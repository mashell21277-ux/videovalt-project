-- VideoVault database for phpMyAdmin / MySQL (XAMPP)
-- Import: phpMyAdmin → Import → choose this file

CREATE DATABASE IF NOT EXISTS `videovault`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `videovault`;

CREATE TABLE IF NOT EXISTS `Video` (
  `id` VARCHAR(36) NOT NULL,
  `title` VARCHAR(191) NOT NULL,
  `description` TEXT NULL,
  `filename` VARCHAR(191) NOT NULL,
  `thumbnail` VARCHAR(191) NULL,
  `category` ENUM('ENTERTAINMENT', 'EDUCATION', 'MUSIC', 'SPORTS') NOT NULL,
  `type` ENUM('VIDEO', 'REEL') NOT NULL DEFAULT 'VIDEO',
  `duration` INT NULL,
  `fileSize` INT NULL,
  `isLive` TINYINT(1) NOT NULL DEFAULT 1,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
