package com.springcommerce.springcommerce.enums;

public enum Category {
    FASHION("1", "Man & Woman Fashion"),
    ELECTRONIC("2", "Electronic"),
    JEWELLERY("3", "Jewellery Accessories");

    private final String id;
    private final String name;

    Category(String id, String name) {
        this.id = id;
        this.name = name;
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public static String getNameById(String id) {
        for (Category category : values()) {
            if (category.getId().equals(id)) {
                return category.getName();
            }
        }
        return null; // Trả về null nếu không tìm thấy
    }

    public static String getIdByName(String name) {
        for (Category category : values()) {
            if (category.getName().equalsIgnoreCase(name)) {
                return category.getId();
            }
        }
        return null; // Trả về null nếu không tìm thấy
    }
}
