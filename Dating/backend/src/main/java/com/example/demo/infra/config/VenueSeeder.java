package com.example.demo.infra.config;

import com.example.demo.features.scheduling.entity.Venue;
import com.example.demo.features.scheduling.repository.VenueRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

/**
 * Seeds the database with real-world venue data for TP.HCM.
 * Only runs when the venues table is empty (safe for ddl-auto=update).
 */
@Component
@RequiredArgsConstructor
public class VenueSeeder implements CommandLineRunner {

    private final VenueRepository venueRepository;

    @Override
    public void run(String... args) {
        if (venueRepository.count() > 0)
            return;

        venueRepository.save(new Venue("The Coffee House - Tran Cao Van", "Quan 3", 10.7862, 106.6906));
        venueRepository.save(new Venue("Cong Caphe - Truong Sa", "Binh Thanh", 10.7998, 106.7072));
        venueRepository.save(new Venue("Phuc Long - Le Loi", "Quan 1", 10.7725, 106.6990));
        venueRepository.save(new Venue("Starbucks - New World", "Quan 1", 10.7732, 106.6968));
        venueRepository.save(new Venue("Highlands Coffee - Nguyen Hue", "Quan 1", 10.7740, 106.7020));
        venueRepository.save(new Venue("The Coffee House - Phan Xich Long", "Phu Nhuan", 10.7993, 106.6822));
        venueRepository.save(new Venue("Phuc Long - 3 Thang 2", "Quan 11", 10.7650, 106.6600));
        venueRepository.save(new Venue("Trung Nguyen Legend - Dong Khoi", "Quan 1", 10.7767, 106.7022));
        venueRepository.save(new Venue("Cong Caphe - Pham Ngoc Thach", "Quan 3", 10.7837, 106.6932));
        venueRepository.save(new Venue("The Coffee House - Su Van Hanh", "Quan 10", 10.7772, 106.6698));
        venueRepository.save(new Venue("Starbucks - Crescent Mall", "Quan 7", 10.7295, 106.7192));
        venueRepository.save(new Venue("Highlands Coffee - Vincom Thu Duc", "Thu Duc", 10.8510, 106.7535));
        venueRepository.save(new Venue("Phuc Long - Vo Van Ngan", "Thu Duc", 10.8488, 106.7710));
        venueRepository.save(new Venue("The Coffee House - Le Van Viet", "Thu Duc", 10.8473, 106.7863));
        venueRepository.save(new Venue("Cong Caphe - Nguyen Hue", "Quan 1", 10.7735, 106.7034));
    }
}
