// src/main/java/com/example/demo/repositories/ListeningContentCacheRepository.java
package com.example.demo.repositories;

import com.example.demo.entities.ListeningContentCache;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ListeningContentCacheRepository extends JpaRepository<ListeningContentCache, Long> {
    // <<< THÊM PHƯƠNG THỨC MỚI VỚI gameSubType >>>
    Optional<ListeningContentCache> findByFolderIdAndLevelAndTopicAndGameSubType(
            Long folderId, int level, String topic, String gameSubType);
}