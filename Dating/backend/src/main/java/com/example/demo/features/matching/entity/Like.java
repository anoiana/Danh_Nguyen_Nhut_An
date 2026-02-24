package com.example.demo.features.matching.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import com.example.demo.features.user.entity.User;

@Entity
@Table(name = "likes")
@Data
@NoArgsConstructor
public class Like {

    public enum Type {
        LIKE, SKIP
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "from_user_id", nullable = false)
    private User fromUser;

    @ManyToOne
    @JoinColumn(name = "to_user_id", nullable = false)
    private User toUser;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Type type = Type.LIKE;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Like(User fromUser, User toUser) {
        this.fromUser = fromUser;
        this.toUser = toUser;
        this.type = Type.LIKE;
        this.createdAt = LocalDateTime.now();
    }

    public Like(User fromUser, User toUser, Type type) {
        this.fromUser = fromUser;
        this.toUser = toUser;
        this.type = type;
        this.createdAt = LocalDateTime.now();
    }
}
