use linkedinmoodle;

delimiter //

CREATE TRIGGER before_users_insert BEFORE INSERT ON users
  FOR EACH ROW
  BEGIN
  	IF (YEAR(NEW.birth_date) > YEAR(NOW()) - 13) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'USER NOT OLD ENOUGH TO SIGN UP';
	END IF;
  
	INSERT INTO linkedinmoodle.accounts(account_type) values('USER');
    SET NEW.account_id = (SELECT last_insert_id());
    
	SET NEW.created_time = NOW();
	SET NEW.employee_flag = 0;
	SET NEW.instructor_flag = 0;
	SET NEW.student_flag = 0;

	IF NEW.visibility IS NULL THEN SET NEW.visibility = 'ALL';
    END IF;
    
  END;
//

CREATE TRIGGER before_users_update BEFORE UPDATE ON users
  FOR EACH ROW
  BEGIN
  
	IF (YEAR(NEW.birth_date) > YEAR(NOW()) - 13) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'USER NOT OLD ENOUGH TO SIGN UP';
	END IF;
  
	IF (NEW.account_id <> OLD.account_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ACCOUNT ID CANNOT BE UPDATED';
	END IF;
    
	IF (NEW.created_time <> OLD.created_time) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CREATED TIME CANNOT BE UPDATED';
	END IF;
    
  END;
//

CREATE TRIGGER before_organizations_insert BEFORE INSERT ON organizations
  FOR EACH ROW
  BEGIN
	INSERT INTO linkedinmoodle.accounts(account_type) values('ORGANIZATION');
    SET NEW.account_id = (SELECT last_insert_id());

    IF NEW.created_time IS NOT NULL THEN SET NEW.created_time = NOW();
    END IF;
    
  END;
//

CREATE TRIGGER after_organizations_insert AFTER INSERT ON organizations
  FOR EACH ROW
  BEGIN

    IF (NEW.organization_type = 'COMPANY') THEN
		INSERT INTO companies(organization_id) VALUES (NEW.organization_id);
	ELSE
		INSERT INTO schools(organization_id) VALUES (NEW.organization_id);
	END IF;

    INSERT INTO organization_administration(organization_id, user_id) VALUES (NEW.organization_id, NEW.creator_id);
    
  END;
//

CREATE TRIGGER before_organizations_update BEFORE UPDATE ON organizations
  FOR EACH ROW
  BEGIN
  
  	IF (NEW.account_id <> OLD.account_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ACCOUNT ID CANNOT BE UPDATED';
	END IF;
    
	IF (NEW.created_time <> OLD.created_time) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CREATED TIME CANNOT BE UPDATED';
	END IF;
    
	IF (NEW.organization_type <> OLD.organization_type) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORGANIZATION TYPE CANNOT BE UPDATED';
	END IF;
    
	IF (NEW.creator_id <> OLD.creator_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CREATOR ID CANNOT BE UPDATED';
	END IF;

  END;
//

CREATE TRIGGER before_connection_requests_insert BEFORE INSERT ON connection_requests
  FOR EACH ROW
  BEGIN
  
	SET NEW.request_status = 'PENDING';
	IF NEW.send_time IS NOT NULL THEN SET NEW.send_time = NOW();
    END IF;
    
  END;
//

CREATE TRIGGER after_connection_requests_update AFTER UPDATE ON connection_requests
  FOR EACH ROW
  BEGIN

	IF NEW.request_status = 'ACCEPTED' THEN 
		CALL add_connection(NEW.sender_id, NEW.receiver_id);
        DELETE FROM connection_requests WHERE sender_id = NEW.sender_id AND receiver_id = NEW.receiver_id;
	ELSEIF NEW.request_status = 'REJECTED' THEN 
		DELETE FROM connection_requests WHERE sender_id = NEW.sender_id AND receiver_id = NEW.receiver_id;
	END IF;
    
  END;
//

CREATE PROCEDURE add_connection( auser_id VARCHAR(32), aconnection_id VARCHAR(32))
BEGIN
    INSERT INTO connections(user_id, connection_id) VALUES (aconnection_id, auser_id);
    INSERT INTO connections(user_id, connection_id) VALUES (auser_id, aconnection_id);
    
	SELECT account_id INTO @UACC FROM users WHERE user_id = auser_id;
	SELECT account_id INTO @CACC FROM users WHERE user_id = aconnection_id;
        
	SELECT COUNT(*) INTO @CU FROM follow WHERE follower_id = @UACC AND following_id = @CACC;
	IF (@CU = 0) THEN
		INSERT INTO follow(follower_id, following_id) VALUES (@UACC, @CACC);
	END IF;
	SELECT COUNT(*) INTO @CC FROM follow WHERE follower_id = @CACC AND following_id = @UACC;
	IF (@CC = 0) THEN
		INSERT INTO follow(follower_id, following_id) VALUES (@CACC, @UACC);
	END IF;
END;
//

CREATE PROCEDURE delete_connection( duser_id VARCHAR(32), dconnection_id VARCHAR(32))
BEGIN
    DELETE FROM connections WHERE user_id = dconnection_id AND connection_id = duser_id;
    DELETE FROM connections WHERE user_id = duser_id AND connection_id = dconnection_id;
    
	SELECT account_id INTO @UACC FROM users WHERE user_id = duser_id;
	SELECT account_id INTO @CACC FROM users WHERE user_id = dconnection_id;
        
	SELECT COUNT(*) INTO @CU FROM follow WHERE follower_id = @UACC AND following_id = @CACC;
	IF (@CU = 1) THEN
		DELETE FROM follow WHERE follower_id = @UACC AND following_id = @CACC;
	END IF;
	SELECT COUNT(*) INTO @CC FROM follow WHERE follower_id = @CACC AND following_id = @UACC;
	IF (@CC = 1) THEN
		DELETE FROM follow WHERE follower_id = @CACC AND following_id = @UACC;
	END IF;
END;
//

CREATE TRIGGER before_messages_update BEFORE UPDATE ON messages
  FOR EACH ROW
  BEGIN
  
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MESSAGES CANNOT BE UPDATED';
    
  END;
//

CREATE TRIGGER before_organization_administration_delete BEFORE DELETE ON organization_administration
  FOR EACH ROW
  BEGIN
  
	DECLARE REC_COUNT INTEGER;
	SET REC_COUNT = (SELECT COUNT(*) FROM organization_administration WHERE organization_id = OLD.organization_id);
    
    IF (REC_COUNT = 1) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORGANIZATIONS MUST HAVE AN ADMINISTRATOR';
    END IF;
    
  END;
//

CREATE TRIGGER before_companies_insert BEFORE INSERT ON companies
  FOR EACH ROW
  BEGIN
	
    SELECT organization_type INTO @T FROM organizations WHERE organization_id = NEW.organization_id;
    
    IF (@T <> 'COMPANY') THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORGANIZATION IS NOT A COMPANY';
	END IF;
    
  END;
//

CREATE TRIGGER before_works_for_insert BEFORE INSERT ON works_for
  FOR EACH ROW
  BEGIN
  
  	IF (NEW.start_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE FUTURE DATE';
	END IF;
  
	IF (NEW.end_date IS NOT NULL AND NEW.end_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'END DATE CANNOT BE FUTURE DATE';
	END IF;
    
	IF (NEW.end_date IS NOT NULL AND NEW.start_date > NEW.end_date) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE GRATER THAN END DATE';
	END IF;

  END;
//

CREATE TRIGGER after_works_for_insert AFTER INSERT ON works_for
  FOR EACH ROW
  BEGIN
  
	DECLARE CURRENTLY_WORKS INTEGER;
	SET CURRENTLY_WORKS = (SELECT COUNT(*) FROM works_for WHERE employee_id = NEW.employee_id AND end_date IS NULL); 
    
	SELECT account_id INTO @EACC FROM users WHERE user_id = NEW.employee_id;
	SELECT account_id INTO @CACC FROM organizations WHERE organization_id = NEW.company_id;
    SELECT COUNT(*) INTO @C FROM follow WHERE follower_id = @EACC AND following_id = @CACC;
    IF (@C = 0) THEN
		INSERT INTO follow(follower_id, following_id) VALUES (@EACC, @CACC);
    END IF;
    
    IF (CURRENTLY_WORKS > 0) THEN
		UPDATE users SET employee_flag = 1 WHERE user_id = NEW.employee_id;
	ELSE
		UPDATE users SET employee_flag = 0 WHERE user_id = NEW.employee_id;
    END IF;
    
  END;
//

CREATE TRIGGER before_works_for_update BEFORE UPDATE ON works_for
  FOR EACH ROW
  BEGIN
  
	IF (NEW.start_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE FUTURE DATE';
	END IF;

	IF (NEW.end_date IS NOT NULL AND NEW.end_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'END DATE CANNOT BE FUTURE DATE';
	END IF;
    
	IF (NEW.end_date IS NOT NULL AND NEW.start_date > NEW.end_date) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE GRATER THAN END DATE';
	END IF;
    
  END;
//

CREATE TRIGGER after_works_for_update AFTER UPDATE ON works_for
  FOR EACH ROW
  BEGIN

	DECLARE CURRENTLY_WORKS INTEGER;
	SET CURRENTLY_WORKS = (SELECT COUNT(*) FROM works_for WHERE employee_id = NEW.employee_id AND end_date IS NULL); 
    
    IF (CURRENTLY_WORKS > 0) THEN
		UPDATE users SET employee_flag = 1 WHERE user_id = NEW.employee_id;
	ELSE
		UPDATE users SET employee_flag = 0 WHERE user_id = NEW.employee_id;
    END IF;
    
  END;
//

CREATE TRIGGER before_job_adverts_insert BEFORE INSERT ON job_adverts
  FOR EACH ROW
  BEGIN
  
	SELECT COUNT(*), MAX(advert_id) INTO @C, @A FROM linkedinmoodle.job_adverts WHERE company_id = NEW.company_id; 
    
    IF @C > 0 THEN 
		SET NEW.advert_id = @A + 1;
	ELSE 
		SET NEW.advert_id = 1;
	END IF;
    
	IF NEW.current_status IS NULL THEN 
		SET NEW.current_status = 'OPEN';
    END IF;
    
  END;
//

CREATE TRIGGER before_job_adverts_update BEFORE UPDATE ON job_adverts
  FOR EACH ROW
  BEGIN
  
	IF (OLD.advert_id <> NEW.advert_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ADVERT ID CANNOT BE CHANGED';
	END IF;
    
  END;
//

CREATE TRIGGER before_schools_insert BEFORE INSERT ON schools
  FOR EACH ROW
  BEGIN
	
	SELECT organization_type INTO @T FROM organizations WHERE organization_id = NEW.organization_id;
    
    IF (@T <> 'SCHOOL') THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORGANIZATION IS NOT A SCHOOL';
	END IF;
    
  END;
//

CREATE TRIGGER before_student_department_insert BEFORE INSERT ON student_department
  FOR EACH ROW
  BEGIN
  
	IF (NEW.start_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE FUTURE DATE';
	END IF;
  
	IF (NEW.graduation_date IS NOT NULL AND NEW.graduation_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'GRADUATION DATE CANNOT BE FUTURE DATE';
	END IF;
    
	IF (NEW.graduation_date IS NOT NULL AND NEW.start_date > NEW.graduation_date) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE GRATER THAN GRADUATION DATE';
	END IF;
    
  END;
//

CREATE TRIGGER after_student_department_insert AFTER INSERT ON student_department
  FOR EACH ROW
  BEGIN
  
	DECLARE CURRENTLY_STUDIES INTEGER;
	SET CURRENTLY_STUDIES = (SELECT COUNT(*) FROM student_department WHERE student_id = NEW.student_id AND graduation_date IS NULL); 
    
	SELECT account_id INTO @UACC FROM users WHERE user_id = NEW.student_id;
    SELECT account_id INTO @SACC FROM organizations WHERE organization_id = NEW.school_id;
	SELECT COUNT(*) INTO @C FROM follow WHERE follower_id = @UACC AND following_id = @SACC;
    IF (@C = 0) THEN
		INSERT INTO follow(follower_id, following_id) VALUES (@UACC, @SACC);
    END IF;
    
    IF (CURRENTLY_STUDIES > 0) THEN
		UPDATE users SET student_flag = 1 WHERE user_id = NEW.student_id;
	ELSE
		UPDATE users SET student_flag = 0 WHERE user_id = NEW.student_id;
    END IF;
    
  END;
//

CREATE TRIGGER before_student_department_update BEFORE UPDATE ON student_department
  FOR EACH ROW
  BEGIN
  
	IF (NEW.start_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE FUTURE DATE';
	END IF;
  
	IF (NEW.graduation_date IS NOT NULL AND NEW.graduation_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'GRADUATION DATE CANNOT BE FUTURE DATE';
	END IF;
    
	IF (NEW.graduation_date IS NOT NULL AND NEW.start_date > NEW.graduation_date) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE GRATER THAN GRADUATION DATE';
	END IF;
    
  END;
//

CREATE TRIGGER after_student_department_update AFTER UPDATE ON student_department
  FOR EACH ROW
  BEGIN

	DECLARE CURRENTLY_STUDIES INTEGER;
	SET CURRENTLY_STUDIES = (SELECT COUNT(*) FROM student_department WHERE student_id = NEW.student_id AND graduation_date IS NULL); 
    
    IF (CURRENTLY_STUDIES > 0) THEN
		UPDATE users SET student_flag = 1 WHERE user_id = NEW.student_id;
	ELSE
		UPDATE users SET student_flag = 0 WHERE user_id = NEW.student_id;
    END IF;
    
  END;
//

CREATE TRIGGER before_instructor_department_insert BEFORE INSERT ON instructor_department
  FOR EACH ROW
  BEGIN
  
	IF (NEW.start_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE FUTURE DATE';
	END IF;
  
	IF (NEW.end_date IS NOT NULL AND NEW.end_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'END DATE CANNOT BE FUTURE DATE';
	END IF;
    
	IF (NEW.end_date IS NOT NULL AND NEW.start_date > NEW.end_date) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE GRATER THAN END DATE';
	END IF;
    
  END;
//

CREATE TRIGGER after_instructor_department_insert AFTER INSERT ON instructor_department
  FOR EACH ROW
  BEGIN
  
	DECLARE CURRENTLY_INSTRUCTOR INTEGER;
	SET CURRENTLY_INSTRUCTOR = (SELECT COUNT(*) FROM instructor_department WHERE instructor_id = NEW.instructor_id AND end_date IS NULL); 
    
    SELECT account_id INTO @IACC FROM users WHERE user_id = NEW.instructor_id;
    SELECT account_id INTO @SACC FROM organizations WHERE organization_id = NEW.school_id;
	SELECT COUNT(*) INTO @C FROM follow WHERE follower_id = @IACC AND following_id = @SACC;
    IF (@C = 0) THEN
		INSERT INTO follow(follower_id, following_id) VALUES (@IACC, @SACC);
    END IF;
    
    IF (CURRENTLY_INSTRUCTOR > 0) THEN
		UPDATE users SET instructor_flag = 1, instructor_rank = 'UNSPECIFIED' WHERE user_id = NEW.instructor_id;
	ELSE
		UPDATE users SET instructor_flag = 0, instructor_rank = NULL WHERE user_id = NEW.instructor_id;
    END IF;
    
  END;
//

CREATE TRIGGER before_instructor_department_update BEFORE UPDATE ON instructor_department
  FOR EACH ROW
  BEGIN
  
	IF (NEW.start_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE FUTURE DATE';
	END IF;
  
	IF (NEW.end_date IS NOT NULL AND NEW.end_date > CURDATE()) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'END DATE CANNOT BE FUTURE DATE';
	END IF;
    
	IF (NEW.end_date IS NOT NULL AND NEW.start_date > NEW.end_date) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'START DATE CANNOT BE GRATER THAN END DATE';
	END IF;
    
  END;
//

CREATE TRIGGER after_instructor_department_update AFTER UPDATE ON instructor_department
  FOR EACH ROW
  BEGIN

	DECLARE CURRENTLY_INSTRUCTOR INTEGER;
	SET CURRENTLY_INSTRUCTOR = (SELECT COUNT(*) FROM instructor_department WHERE instructor_id = NEW.instructor_id AND end_date IS NULL); 
    
    IF (CURRENTLY_INSTRUCTOR > 0) THEN
		UPDATE users SET instructor_flag = 1, instructor_rank = 'UNSPECIFIED' WHERE user_id = NEW.instructor_id;
	ELSE
		UPDATE users SET instructor_flag = 0, instructor_rank = NULL WHERE user_id = NEW.instructor_id;
    END IF;
    
  END;
//

CREATE TRIGGER before_sections_insert BEFORE INSERT ON sections
  FOR EACH ROW
  BEGIN
	
	SELECT COUNT(*) INTO @C FROM instructor_department WHERE instructor_id = NEW.creator_instructor AND school_id = NEW.school_id AND department = NEW.department;
    
    IF (@C > 0) THEN
		INSERT INTO linkedinmoodle.accounts(account_type) values('SECTION');
		SET NEW.account_id = (SELECT last_insert_id());
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'THE USER IS NOT AN INSTRUCTOR IN THIS DEPARTMENT';
    END IF;
    
  END;
//

CREATE TRIGGER after_sections_insert AFTER INSERT ON sections
  FOR EACH ROW
  BEGIN
	
	INSERT INTO section_instructor(section_id, instructor_id) VALUES (NEW.section_id, NEW.creator_instructor);

  END;
//

CREATE TRIGGER before_sections_update BEFORE UPDATE ON sections
  FOR EACH ROW
  BEGIN

	IF (NEW.account_id <> OLD.account_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ACCOUNT ID CANNOT BE UPDATED';
	END IF;
    
	IF (NEW.creator_instructor = OLD.creator_instructor) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CREATOR INSTRUCTOR CANNOT BE UPDATED';
	END IF;

  END;
//

CREATE TRIGGER before_section_instructor_insert BEFORE INSERT ON section_instructor
  FOR EACH ROW
  BEGIN
  
	SELECT school_id, department INTO @SCH, @DEPT FROM sections WHERE section_id = NEW.section_id;
	SELECT COUNT(*) INTO @C FROM instructor_department WHERE instructor_id = NEW.instructor_id AND school_id = @SCH AND department = @DEPT;
    
    IF (@C = 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'THE USER IS NOT AN INSTRUCTOR IN THIS DEPARTMENT';
    END IF;
    
  END;
//

CREATE TRIGGER before_section_instructor_delete BEFORE DELETE ON section_instructor
  FOR EACH ROW
  BEGIN
  
	DECLARE REC_COUNT INTEGER;
	SET REC_COUNT = (SELECT COUNT(*) FROM section_instructor WHERE section_id = OLD.section_id);
    
    IF (REC_COUNT = 1) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SECTIONS MUST HAVE AN INSTRUCTOR';
    END IF;
    
  END;
//

CREATE TRIGGER before_enroll_insert BEFORE INSERT ON enroll
  FOR EACH ROW
  BEGIN
  
	SELECT school_id, department, account_id, section_year INTO @SCH, @DEPT, @ACC, @YEA FROM sections WHERE section_id = NEW.section_id;
    SELECT COUNT(*), graduation_date INTO @C, @D FROM student_department WHERE student_id = NEW.student_id AND school_id = @SCH AND department = @DEPT;
    SELECT account_id INTO @SID FROM users WHERE user_id = NEW.student_id;
    
    IF (@C > 0 AND (@D IS NULL OR YEAR(@D) >= @YEA)) THEN
		INSERT INTO follow(follower_id, following_id) VALUES (@SID, @ACC);
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'THE USER IS NOT A STUDENT IN THIS DEPARTMENT';
    END IF;
    
  END;
//

CREATE TRIGGER before_submit_insert BEFORE INSERT ON submit
  FOR EACH ROW
  BEGIN
  
	IF (NEW.submited_file IS NOT NULL) THEN
		SET NEW.submitted_time = NOW();
	ELSE
		SET NEW.submitted_time = NULL;
	END IF;
    
  END;
//

CREATE TRIGGER before_submit_update BEFORE UPDATE ON submit
  FOR EACH ROW
  BEGIN
  
	IF (NEW.submited_file IS NOT NULL) THEN
		SET NEW.submitted_time = NOW();
	ELSE
		SET NEW.submitted_time = NULL;
	END IF;
    
  END;
//

CREATE TRIGGER before_shared_items_insert BEFORE INSERT ON shared_items
  FOR EACH ROW
  BEGIN
  
	SET NEW.send_time = NOW();
    
  END;
//

CREATE TRIGGER before_shared_items_update BEFORE UPDATE ON shared_items
  FOR EACH ROW
  BEGIN
    
	IF (OLD.account_id <> NEW.account_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ACCOUNT ID CANNOT BE UPDATED';
    END IF;
    
	IF (OLD.send_time <> NEW.send_time) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEND TIME CANNOT BE UPDATED';
    END IF;
    
	IF (OLD.item_type <> NEW.item_type) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ITEM TYPE CANNOT BE UPDATED';
    END IF;
    
	IF (OLD.content <> NEW.content) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CONTENT CANNOT BE UPDATED';
    END IF;
    
  END;
//

CREATE TRIGGER before_posts_insert BEFORE INSERT ON posts
  FOR EACH ROW
  BEGIN
  
	SELECT item_type INTO @IT FROM shared_items WHERE shared_item_id = NEW.shared_item_id;
    
    IF (@IT = 'COMMENT') THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ITEM ID IS BELONG TO A COMMENT';
    END IF;
    
  END;
//

CREATE TRIGGER before_posts_update BEFORE UPDATE ON posts
  FOR EACH ROW
  BEGIN
    
    IF (OLD.shared_item_id <> NEW.shared_item_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SHARED ITEM ID CANNOT BE UPDATED';
    END IF;
    
  END;
//

CREATE TRIGGER before_comments_insert BEFORE INSERT ON comments
  FOR EACH ROW
  BEGIN
  
	SELECT item_type INTO @IT FROM shared_items WHERE shared_item_id = NEW.shared_item_id;
    
    IF (@IT = 'POST') THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ITEM ID IS BELONG TO A POST';
    END IF;
    
  END;
//

CREATE TRIGGER before_comments_update BEFORE UPDATE ON comments
  FOR EACH ROW
  BEGIN
    
    IF (OLD.shared_item_id <> NEW.shared_item_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SHARED ITEM ID CANNOT BE UPDATED';
    END IF;
    
  END;
//

CREATE TRIGGER before_follow_insert BEFORE INSERT ON follow
  FOR EACH ROW
  BEGIN
  
	SELECT COUNT(*) INTO @C FROM users WHERE account_id = NEW.follower_id;
    
    IF (@C = 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FOLLOWER ACCOUNT MUST BE A USER';
    END IF;
    
    SET NEW.follow_time = NOW();
    
  END;
//

CREATE TRIGGER before_follow_update BEFORE UPDATE ON follow
  FOR EACH ROW
  BEGIN
    
    IF (OLD.follower_id <> NEW.follower_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FOLLOWER ID CANNOT BE UPDATED';
    END IF;
    
	IF (OLD.following_id <> NEW.following_id) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FOLLOWING ID CANNOT BE UPDATED';
    END IF;
    
	IF (OLD.follow_time <> NEW.follow_time) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FOLLOWING TIME CANNOT BE UPDATED';
    END IF;
    
  END;
//