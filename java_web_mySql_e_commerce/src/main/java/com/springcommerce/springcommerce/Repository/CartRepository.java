package com.springcommerce.springcommerce.Repository;

import com.springcommerce.springcommerce.entity.Cart;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartRepository extends JpaRepository<Cart, Long> {
    Optional<Cart> findFirstByOrderByIdCartAsc();
    @Query("SELECT c FROM Cart c JOIN c.cartCustomers cc WHERE cc.customer.userId = :customerId")
    Cart findByCustomerId(@Param("customerId") Long customerId);
}
