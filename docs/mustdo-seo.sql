SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

CREATE SCHEMA IF NOT EXISTS `mustdo-seo` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;
USE `mustdo-seo` ;

-- -----------------------------------------------------
-- Table `mustdo-seo`.`urls`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mustdo-seo`.`urls` ;

CREATE  TABLE IF NOT EXISTS `mustdo-seo`.`urls` (
  `url_id` INT NOT NULL AUTO_INCREMENT ,
  `url_processed` CHAR(1) NULL DEFAULT 0 ,
  `url_url_text_md5_hex` VARCHAR(45) NULL ,
  `url_url_text` TEXT NULL ,
  `url_inlink_canonical_list` TEXT NULL ,
  `url_canonical_list` TEXT NULL ,
  `url_inlink_list` TEXT NULL ,
  `url_inlink_anchor_text` TEXT NULL ,
  `url_title_list` TEXT NULL ,
  `url_description_list` TEXT NULL ,
  `url_internal_link_list` TEXT NULL ,
  `url_external_link_list` TEXT NULL ,
  `url_content_md5_hex` VARCHAR(45) NULL ,
  `url_script_src_list` TEXT NULL ,
  `url_scripts_inline_amount` INT NULL ,
  `url_scripts_inline_length` INT NULL ,
  `url_styles_scr_list` TEXT NULL ,
  `url_styles_inline_amount` INT NULL ,
  `url_styles_inline_length` INT NULL ,
  `url_img_list` TEXT NULL ,
  `url_img_alt_text` TEXT NULL ,
  `url_h1_amount` INT NULL ,
  `url_h1_text` TEXT NULL ,
  `url_h2_h6_amount` INT NULL ,
  `url_h2_h6_text` TEXT NULL ,
  `url_bold_strong_amount` INT NULL ,
  `url_bold_strong_text` TEXT NULL ,
  `url_italic_em_amount` INT NULL ,
  `url_italic_em_text` TEXT NULL ,
  `url_response_code` CHAR(3) NULL ,
  `url_response_message` VARCHAR(255) NULL ,
  `url_response_header` TEXT NULL ,
  `url_updated` TIMESTAMP ,
  PRIMARY KEY (`url_id`) )
ENGINE = InnoDB;

CREATE UNIQUE INDEX `url_url_md5_hex_UNIQUE` ON `mustdo-seo`.`urls` (`url_url_text_md5_hex` ASC) ;


-- -----------------------------------------------------
-- Table `mustdo-seo`.`scripts`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mustdo-seo`.`scripts` ;

CREATE  TABLE IF NOT EXISTS `mustdo-seo`.`scripts` (
  `scp_id` INT NOT NULL AUTO_INCREMENT ,
  `scp_script_src_md5_hex` VARCHAR(45) NULL ,
  `scp_script_src` TEXT NULL ,
  `scp_updated` TIMESTAMP ,
  PRIMARY KEY (`scp_id`) )
ENGINE = InnoDB;

CREATE UNIQUE INDEX `scp_script_src_md5_hex_UNIQUE` ON `mustdo-seo`.`scripts` (`scp_script_src_md5_hex` ASC) ;


-- -----------------------------------------------------
-- Table `mustdo-seo`.`titles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mustdo-seo`.`titles` ;

CREATE  TABLE IF NOT EXISTS `mustdo-seo`.`titles` (
  `tit_id` INT NOT NULL AUTO_INCREMENT ,
  `tit_title_md5_hex` VARCHAR(45) NULL ,
  `tit_title` TEXT NULL ,
  `tit_updated` TIMESTAMP ,
  PRIMARY KEY (`tit_id`) )
ENGINE = InnoDB;

CREATE UNIQUE INDEX `tit_title_md5_hex_UNIQUE` ON `mustdo-seo`.`titles` (`tit_title_md5_hex` ASC) ;


-- -----------------------------------------------------
-- Table `mustdo-seo`.`styles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mustdo-seo`.`styles` ;

CREATE  TABLE IF NOT EXISTS `mustdo-seo`.`styles` (
  `sty_id` INT NOT NULL AUTO_INCREMENT ,
  `sty_style_src_md5_hex` VARCHAR(45) NULL ,
  `sty_style_src` TEXT NULL ,
  `sty_updated` TIMESTAMP ,
  PRIMARY KEY (`sty_id`) )
ENGINE = InnoDB;

CREATE UNIQUE INDEX `sty_style_src_md5_hex_UNIQUE` ON `mustdo-seo`.`styles` (`sty_style_src_md5_hex` ASC) ;


-- -----------------------------------------------------
-- Table `mustdo-seo`.`descriptions`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mustdo-seo`.`descriptions` ;

CREATE  TABLE IF NOT EXISTS `mustdo-seo`.`descriptions` (
  `desc_id` INT NOT NULL AUTO_INCREMENT ,
  `desc_description_md5_hex` VARCHAR(45) NULL ,
  `desc_description` TEXT NULL ,
  `desc_updated` TIMESTAMP ,
  PRIMARY KEY (`desc_id`) )
ENGINE = InnoDB;

CREATE UNIQUE INDEX `desc_description_md5_hex_UNIQUE` ON `mustdo-seo`.`descriptions` (`desc_description_md5_hex` ASC) ;


-- -----------------------------------------------------
-- Table `mustdo-seo`.`images`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mustdo-seo`.`images` ;

CREATE  TABLE IF NOT EXISTS `mustdo-seo`.`images` (
  `img_id` INT NOT NULL AUTO_INCREMENT ,
  `img_image_src_md5_hex` VARCHAR(45) NULL ,
  `img_image_src` TEXT NULL ,
  `img_updated` TIMESTAMP ,
  PRIMARY KEY (`img_id`) )
ENGINE = InnoDB;

CREATE UNIQUE INDEX `img_image_src_md5_hex_UNIQUE` ON `mustdo-seo`.`images` (`img_image_src_md5_hex` ASC) ;


-- -----------------------------------------------------
-- Table `mustdo-seo`.`contents`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mustdo-seo`.`contents` ;

CREATE  TABLE IF NOT EXISTS `mustdo-seo`.`contents` (
  `cont_id` INT NOT NULL AUTO_INCREMENT ,
  `cont_content_md5_hex` VARCHAR(45) NULL ,
  `cont_updated` TIMESTAMP ,
  PRIMARY KEY (`cont_id`) )
ENGINE = InnoDB;

CREATE UNIQUE INDEX `cont_description_md5_hex_UNIQUE` ON `mustdo-seo`.`contents` (`cont_content_md5_hex` ASC) ;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
