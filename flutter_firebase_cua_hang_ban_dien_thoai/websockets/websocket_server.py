import asyncio
import json
import websockets
from websockets.exceptions import ConnectionClosed, ConnectionClosedOK, ConnectionClosedError
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone
import inspect

print(f"websockets module loaded from: {inspect.getfile(websockets)}")
print(f"asyncio module loaded from: {inspect.getfile(asyncio)}")
print(f"websockets version being used: {websockets.__version__}")

# Kiểm tra phiên bản websockets
try:
    # Phiên bản tối thiểu là 10.0 để hỗ trợ signature (websocket, path)
    if not hasattr(websockets, '__version__') or websockets.__version__ < "10.0":
        raise ImportError(f"websockets version {getattr(websockets, '__version__', 'unknown')} is too old. Please upgrade to 10.0 or later (12.0 recommended).")
    print(f"Confirmed websockets version {websockets.__version__} is suitable.")
except ImportError as e:
    print(f"Error with websockets installation: {e}")
    exit()

# --- Firebase Admin SDK Setup ---
try:
    cred = credentials.Certificate('flutterfinal-34766-firebase-adminsdk-fbsvc-390d3ef6d5.json') # Đảm bảo file này tồn tại
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase Admin SDK initialized successfully.")
except Exception as e:
    print(f"Error initializing Firebase Admin SDK: {e}")
    exit()
# --- End Firebase Admin SDK Setup ---

product_rooms = {}
PORT = 8765

async def notify_clients(product_id, message_data):
    if product_id in product_rooms:
        message_str = json.dumps(message_data, ensure_ascii=False, default=str)
        print(f"Broadcasting to room {product_id}: {message_str}")
        clients_in_room = list(product_rooms[product_id])
        for client_ws in clients_in_room:
            try:
                await client_ws.send(message_str)
            except (ConnectionClosed, ConnectionClosedOK, ConnectionClosedError):
                print(f"Client {client_ws.remote_address} in room {product_id} disconnected during broadcast. Removing.")
                product_rooms[product_id].discard(client_ws)
                if not product_rooms[product_id]:
                    print(f"Room {product_id} is now empty, removing room.")
                    del product_rooms[product_id]
            except Exception as e:
                print(f"Error sending message to client {client_ws.remote_address} in room {product_id}: {e}")

async def handle_comment_actions(websocket: websockets.WebSocketServerProtocol, path: str):
    print(f"New WebSocket connection from {websocket.remote_address} requesting path: {path}")
    print(f"Headers received: {websocket.request_headers}")
    product_id = None

    try:
        # --- CẬP NHẬT XỬ LÝ CORS (Cách 1c) ---
        origin = websocket.request_headers.get("Origin")
        if origin is not None: # Nếu có header Origin
            # Kiểm tra xem origin có phải là localhost (cho môi trường dev)
            # bao gồm cả http://localhost:[port] và http://127.0.0.1:[port]
            is_dev_localhost = origin.startswith("http://localhost:") or origin.startswith("http://127.0.0.1:")
            
            # Danh sách các origin được phép cho môi trường production
            allowed_production_origins = [
                # "https://your-production-app.com", # Bỏ comment và thay thế bằng domain production của bạn
                # "https://another-trusted-domain.com",
            ]

            if not is_dev_localhost and origin not in allowed_production_origins:
                # Nếu không phải localhost dev và cũng không nằm trong danh sách production được phép
                print(f"Rejected connection from origin: {origin} (not an allowed development or production origin)")
                await websocket.close(code=1008, reason="Invalid origin")
                return
            else:
                # Nếu là localhost dev hoặc nằm trong danh sách production được phép
                print(f"Accepted connection from origin: {origin}")
        else:
            # Cho phép kết nối nếu không có Origin header (ví dụ từ client mobile native, Postman)
            print(f"Accepted connection with no Origin header (e.g., native mobile client or tool).")
        # --- KẾT THÚC CẬP NHẬT XỬ LÝ CORS ---

        path_parts = path.strip("/").split("/")
        print(f"Parsed path parts: {path_parts}")

        if not (len(path_parts) == 3 and path_parts[0] == "ws" and path_parts[1] == "comments" and path_parts[2]):
            error_message = f"Invalid path format: '{path}'. Expected /ws/comments/<productId>."
            print(error_message)
            await websocket.close(code=1003, reason=error_message)
            return
        
        product_id = path_parts[2]
        print(f"Client {websocket.remote_address} successfully parsed productId: {product_id}")

        if product_id not in product_rooms:
            product_rooms[product_id] = set()
        product_rooms[product_id].add(websocket)
        print(f"Client {websocket.remote_address} added to room {product_id}. Room size: {len(product_rooms[product_id])}")

        async for message_str in websocket:
            print(f"Received from client {websocket.remote_address} in room {product_id}: {message_str}")
            try:
                message_data = json.loads(message_str)
                action_type = message_data.get("type")
                payload = message_data.get("payload")

                if not action_type or not payload:
                    error_msg = "Invalid message: 'type' or 'payload' missing."
                    print(error_msg)
                    await websocket.send(json.dumps({"type": "error", "data": {"message": error_msg}}))
                    continue

                if action_type == "post_comment":
                    requesting_user_id = payload.get("userDocId")
                    existing_comments_query = db.collection('rating') \
                        .where('productId', '==', product_id) \
                        .where('userDocId', '==', requesting_user_id) \
                        .limit(1) \
                        .stream()
                    has_existing_comment = any(existing_comments_query)
                    
                    if has_existing_comment:
                        error_msg = "You have already reviewed this product. You can edit your existing review."
                        print(f"User {requesting_user_id} attempted to post a new review for product {product_id} but already has one. {error_msg}")
                        await websocket.send(json.dumps({"type": "error", "data": {"message": error_msg, "code": "ALREADY_REVIEWED"}}))
                        continue

                    if payload.get("productId") != product_id:
                        error_msg = f"Mismatched productId in payload: path '{product_id}', payload '{payload.get('productId')}'"
                        print(error_msg)
                        await websocket.send(json.dumps({"type": "error", "data": {"message": error_msg}}))
                        continue
                    
                    new_rating_ref = db.collection('rating').document()
                    comment_doc_id = new_rating_ref.id
                    comment_to_save = {
                        "comment": payload.get("comment"), "numberOfStars": payload.get("numberOfStars"),
                        "userDocId": requesting_user_id, "customerName": payload.get("customerName"),
                        "productId": product_id, "timestamp": datetime.now(timezone.utc)
                    }
                    new_rating_ref.set(comment_to_save)
                    product_ref = db.collection('product').document(product_id)
                    product_ref.update({"comments": firestore.ArrayUnion([comment_doc_id])})
                    print(f"New comment {comment_doc_id} by {payload.get('customerName')} saved for product {product_id}")
                    saved_comment_snap = new_rating_ref.get() 
                    if saved_comment_snap.exists:
                        saved_comment_data = saved_comment_snap.to_dict()
                        saved_comment_data["id"] = comment_doc_id
                        if isinstance(saved_comment_data.get("timestamp"), datetime):
                            saved_comment_data["timestamp"] = saved_comment_data["timestamp"].isoformat()
                        await notify_clients(product_id, {"type": "new_comment", "data": saved_comment_data})
                    else:
                        print(f"Error: Comment {comment_doc_id} not found after saving.")

                elif action_type == "edit_comment":
                    comment_id = payload.get("commentId")
                    requesting_user_id = payload.get("userDocId")
                    rating_ref = db.collection('rating').document(comment_id)
                    comment_doc = rating_ref.get()
                    if not comment_doc.exists:
                        error_msg = f"Comment {comment_id} not found for editing."
                        print(error_msg)
                        await websocket.send(json.dumps({"type": "error", "data": {"message": error_msg}}))
                        continue
                    comment_data = comment_doc.to_dict()
                    if comment_data.get("userDocId") != requesting_user_id:
                        error_msg = f"User {requesting_user_id} does not have permission to edit comment {comment_id}."
                        print(error_msg)
                        await websocket.send(json.dumps({"type": "error", "data": {"message": "Permission denied to edit this comment."}}))
                        continue
                    updated_fields = {
                        "comment": payload.get("comment"), "numberOfStars": payload.get("numberOfStars"),
                        "timestamp": datetime.now(timezone.utc)
                    }
                    rating_ref.update(updated_fields)
                    print(f"Comment {comment_id} updated for product {product_id} by user {requesting_user_id}")
                    updated_comment_snap = rating_ref.get()
                    if updated_comment_snap.exists:
                        updated_comment_data = updated_comment_snap.to_dict()
                        updated_comment_data["id"] = comment_id
                        if isinstance(updated_comment_data.get("timestamp"), datetime):
                            updated_comment_data["timestamp"] = updated_comment_data["timestamp"].isoformat()
                        await notify_clients(product_id, {"type": "updated_comment", "data": updated_comment_data})
                    else:
                        print(f"Error: Comment {comment_id} not found after update (should not happen).")

                elif action_type == "delete_comment":
                    comment_id = payload.get("commentId")
                    requesting_user_id = payload.get("userDocId")
                    rating_ref = db.collection('rating').document(comment_id)
                    comment_doc = rating_ref.get()
                    if not comment_doc.exists:
                        error_msg = f"Comment {comment_id} not found for deletion."
                        print(error_msg)
                        await websocket.send(json.dumps({"type": "error", "data": {"message": error_msg}}))
                        continue
                    comment_data = comment_doc.to_dict()
                    if comment_data.get("userDocId") != requesting_user_id:
                        error_msg = f"User {requesting_user_id} does not have permission to delete comment {comment_id}."
                        print(error_msg)
                        await websocket.send(json.dumps({"type": "error", "data": {"message": "Permission denied to delete this comment."}}))
                        continue
                    rating_ref.delete()
                    product_ref = db.collection('product').document(product_id)
                    product_ref.update({"comments": firestore.ArrayRemove([comment_id])})
                    print(f"Comment {comment_id} deleted for product {product_id} by user {requesting_user_id}")
                    await notify_clients(product_id, {"type": "deleted_comment", "data": {"commentId": comment_id, "productId": product_id}})
                else:
                    error_msg = f"Unknown action type: {action_type}"
                    print(error_msg)
                    await websocket.send(json.dumps({"type": "error", "data": {"message": error_msg}}))

            except json.JSONDecodeError:
                print(f"Invalid JSON received from {websocket.remote_address} in room {product_id}.")
                await websocket.send(json.dumps({"type": "error", "data": {"message": "Invalid JSON format received"}}))
            except Exception as e:
                print(f"Error processing message for client {websocket.remote_address} in room {product_id}: {e}")
                await websocket.send(json.dumps({"type": "error", "data": {"message": f"Server error processing message."}}))

    except (ConnectionClosed, ConnectionClosedOK, ConnectionClosedError) as e:
        print(f"Client {websocket.remote_address} (path: {websocket.path}) disconnected. Code: {e.code}, Reason: {getattr(e, 'reason', 'N/A')}")
    except Exception as e:
        print(f"An unexpected error occurred with client {websocket.remote_address} (path: {websocket.path}): {e}")
        if not websocket.closed:
            await websocket.close(code=1011, reason="Unexpected server error")
    finally:
        if product_id and product_id in product_rooms and websocket in product_rooms[product_id]:
            product_rooms[product_id].discard(websocket)
            print(f"Client {websocket.remote_address} removed from room {product_id}. Room size: {len(product_rooms[product_id])}")
            if not product_rooms[product_id]:
                del product_rooms[product_id]
                print(f"Room {product_id} was empty and has been deleted.")
        else:
            print(f"Client {websocket.remote_address} (path: {websocket.path}) cleanup. Client may not have been in a room or product_id was not set.")

async def main():
    if 'db' not in globals() or db is None:
        print("Critical Error: Firebase DB not initialized globally. Exiting.")
        return

    async with websockets.serve(
        handle_comment_actions,
        "0.0.0.0",
        PORT
    ) as server:
        print(f"WebSocket server started on ws://0.0.0.0:{PORT}")
        await asyncio.Future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer shutting down manually...")
    except Exception as e:
        print(f"Server failed to run or encountered a critical error: {e}")