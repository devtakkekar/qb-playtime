CREATE TABLE IF NOT EXISTS `playtime` (
  `citizenid` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `seconds` int NOT NULL DEFAULT 0,
  `join_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`),
  KEY `seconds_idx` (`seconds`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


