import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/folder_list_view_model.dart';
import '../model/folder.dart';
import '../../../core/widgets/custom_loading_widget.dart';

class FolderSelectionDialog extends StatelessWidget {
  final int currentFolderId;

  const FolderSelectionDialog({super.key, required this.currentFolderId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FolderListViewModel()..loadUserDataAndFetchFolders(),
      child: _FolderSelectionContent(currentFolderId: currentFolderId),
    );
  }
}

class _FolderSelectionContent extends StatefulWidget {
  final int currentFolderId;

  const _FolderSelectionContent({required this.currentFolderId});

  @override
  State<_FolderSelectionContent> createState() =>
      _FolderSelectionContentState();
}

class _FolderSelectionContentState extends State<_FolderSelectionContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<FolderListViewModel>();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50 &&
          !viewModel.isLoadingMore &&
          viewModel.hasMore) {
        viewModel.fetchMoreFolders();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FolderListViewModel>();

    return AlertDialog(
      title: const Text('Chọn thư mục chuyển đến'),
      content: SizedBox(
        width: double.maxFinite,
        child:
            viewModel.isBusy
                ? const Center(child: CustomLoadingWidget())
                : viewModel.folders.isEmpty
                ? const Center(child: Text("Bạn chưa có thư mục nào khác"))
                : ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: viewModel.folders.length + 1,
                  itemBuilder: (context, index) {
                    if (index == viewModel.folders.length) {
                      return viewModel.hasMore
                          ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                          : const SizedBox.shrink();
                    }

                    final folder = viewModel.folders[index];
                    // Skip current folder
                    if (folder.id == widget.currentFolderId) {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      leading: const Icon(Icons.folder, color: Colors.amber),
                      title: Text(folder.name),
                      subtitle: Text('${folder.vocabularyCount} từ'),
                      onTap: () {
                        Navigator.pop(context, folder.id);
                      },
                    );
                  },
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
