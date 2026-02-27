package com.example.demo.features.scheduling.repository;

import com.example.demo.features.scheduling.entity.Venue;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VenueRepository extends JpaRepository<Venue, Long> {
}
