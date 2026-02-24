package com.example.demo.features.matching.repository;

import com.example.demo.features.matching.entity.Like;
import com.example.demo.features.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LikeRepository extends JpaRepository<Like, Long> {

    boolean existsByFromUserAndToUser(User fromUser, User toUser);

    boolean existsByFromUserAndToUserAndType(User fromUser, User toUser, Like.Type type);

    @Query("SELECT l.toUser.id FROM Like l WHERE l.fromUser.id = :userId")
    List<Long> findLikedUserIds(@Param("userId") Long userId);

    @Query("SELECT l.fromUser.id FROM Like l WHERE l.toUser.id = :userId AND l.type = :type")
    List<Long> findUserIdsWhoLikedMe(@Param("userId") Long userId, @Param("type") Like.Type type);

    @Query("SELECT COUNT(l) FROM Like l WHERE l.fromUser.id = :userId AND l.createdAt >= :startOfDay")
    long countInteractionsToday(@Param("userId") Long userId, @Param("startOfDay") java.time.LocalDateTime startOfDay);
}
