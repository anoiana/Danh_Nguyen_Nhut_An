package com.example.demo.features.scheduling.repository;

import com.example.demo.features.scheduling.entity.Activity;
import com.example.demo.features.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ActivityRepository extends JpaRepository<Activity, Long> {
    List<Activity> findByUserOrderByCreatedAtDesc(User user);

    Long countByUserAndIsReadFalse(User user);
}
