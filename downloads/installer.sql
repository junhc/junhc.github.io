SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for installer_oie_log
-- ----------------------------
DROP TABLE IF EXISTS `installer_oie_log`;
CREATE TABLE `installer_oie_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `exec_user` varchar(60) NOT NULL COMMENT '执行者名称',
  `exec_host` varchar(60) DEFAULT NULL COMMENT '执行的服务器ip',
  `exec_sql_name` varchar(1024) DEFAULT NULL COMMENT '执行的sql文件名称',
  `exec_status` bigint(20) DEFAULT NULL COMMENT '执行返回的状态，0为成功，1为失败',
  `sql_type` bigint(20) DEFAULT NULL COMMENT 'sql类型，1为修改sql，2为初始化sql',
  `exec_data` varchar(2048) DEFAULT NULL COMMENT '执行返回的结果',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for installer_sequence
-- ----------------------------
DROP TABLE IF EXISTS `installer_sequence`;
CREATE TABLE `installer_sequence` (
  `seq_name` varchar(255) NOT NULL,
  `min_value` bigint(15) NOT NULL,
  `max_value` bigint(15) NOT NULL,
  `current_val` bigint(15) NOT NULL,
  `increment_val` int(11) NOT NULL DEFAULT '1',
  PRIMARY KEY (`seq_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of installer_sequence
-- ----------------------------
BEGIN;
INSERT INTO `installer_sequence` VALUES ('seq_no', 1, 999999999999999, 19041117591398, 1);
COMMIT;

-- ----------------------------
-- Function structure for seq_nextval
-- ----------------------------
DROP FUNCTION IF EXISTS `seq_nextval`;
delimiter ;;
CREATE DEFINER=`aldidbadmin`@`%` FUNCTION `seq_nextval`(`NAME` VARCHAR(255)) RETURNS bigint(20)
BEGIN
DECLARE _cur BIGINT;
DECLARE _maxvalue BIGINT;
UPDATE installer_sequence
SET current_val = current_val + increment_val
WHERE
	seq_name = `NAME`;

SELECT
	current_val,
	max_value INTO _cur,
	_maxvalue
FROM
	installer_sequence
WHERE
	seq_name = `NAME`;
IF (_cur >= _maxvalue) THEN
	UPDATE installer_sequence
SET current_val = minvalue
WHERE
	seq_name = `NAME`;
END
IF;
RETURN _cur;
END;
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;


-- ----------------------------
-- 一款基于MySQL的分布式自增序列发号器
-- SET @id = `installer`.`seq_nextval` ('seq_no');
-- ----------------------------
