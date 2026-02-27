package com.example.demo.features.scheduling.service;

import com.example.demo.features.scheduling.entity.Venue;
import com.example.demo.features.scheduling.repository.VenueRepository;
import com.example.demo.features.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.Random;

/**
 * Service responsible for intelligent venue selection using GPS-based midpoint
 * matching.
 * Implements the Haversine formula to calculate real-world distances between
 * coordinates.
 */
@Service
@RequiredArgsConstructor
public class VenueService {

    private static final double EARTH_RADIUS_KM = 6371.0;

    private final VenueRepository venueRepository;

    /**
     * Selects the best venue located closest to the midpoint between two users.
     * Falls back to a random venue if either user has no GPS coordinates.
     */
    public Venue findBestVenue(User u1, User u2) {
        List<Venue> venues = venueRepository.findAll();
        if (venues.isEmpty())
            return null;

        boolean hasCoordinates = u1.getLatitude() != null && u1.getLongitude() != null
                && u2.getLatitude() != null && u2.getLongitude() != null;

        if (!hasCoordinates) {
            return venues.get(new Random().nextInt(venues.size()));
        }

        double midLat = (u1.getLatitude() + u2.getLatitude()) / 2;
        double midLng = (u1.getLongitude() + u2.getLongitude()) / 2;

        return venues.stream()
                .min(Comparator.comparingDouble(v -> haversine(midLat, midLng, v.getLatitude(), v.getLongitude())))
                .orElse(venues.get(0));
    }

    /**
     * Haversine formula — calculates the great-circle distance (km) between two
     * points on a sphere given their latitude and longitude in decimal degrees.
     */
    private double haversine(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                        * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }
}
