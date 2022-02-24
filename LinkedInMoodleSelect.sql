-- All possible INSERT statements have a sample in  article 7. So I will show some samples for UPDATE and DELETE statements
UPDATE linkedinmoodle.works_for 
SET end_date = '2021-01-01' 
WHERE employee_id = 'aando' AND company_id = 'toyota' AND start_date = '2019-12-19';

UPDATE linkedinmoodle.organizations 
SET organization_name = 'meta', organization_id = 'meta' 
WHERE organization_id = 'facebook';

UPDATE linkedinmoodle.assignment 
SET deadline = '2021-01-11 00:00:00' 
WHERE section_id = 1004 AND title = 'assignment1';

DELETE FROM linkedinmoodle.assignment
WHERE section_id = 893;

DELETE FROM linkedinmoodle.sections
WHERE section_id = 893;

DELETE FROM linkedinmoodle.messages
WHERE message_id = 10;

-- 1 TABLE
-- Find the distribution of user roles
SELECT 
CASE
	WHEN employee_flag = 0 AND instructor_flag = 0 AND student_flag = 0 THEN 'no role'
    WHEN employee_flag = 0 AND instructor_flag = 0 AND student_flag = 1 THEN 'student'
    WHEN employee_flag = 0 AND instructor_flag = 1 AND student_flag = 0 THEN 'instructor'
    WHEN employee_flag = 0 AND instructor_flag = 1 AND student_flag = 1 THEN 'instructor, student'
    WHEN employee_flag = 1 AND instructor_flag = 0 AND student_flag = 0 THEN 'employee'
    WHEN employee_flag = 1 AND instructor_flag = 0 AND student_flag = 1 THEN 'employee, student'
    WHEN employee_flag = 1 AND instructor_flag = 1 AND student_flag = 0 THEN 'employee, instructor'
	WHEN employee_flag = 1 AND instructor_flag = 1 AND student_flag = 1 THEN 'employee, instructor, student'
    END AS 'role' , COUNT(*) AS 'number of records'
FROM linkedinmoodle.users
GROUP BY employee_flag, instructor_flag, student_flag
ORDER BY employee_flag, instructor_flag, student_flag;

-- Find the distribution of studens gpa's
SELECT CONCAT(0.5 * FLOOR(gpa/0.5 - 0.001), '-' ,  0.5 * FLOOR(gpa/0.5 - 0.001) + 0.5) AS gpa_range, COUNT(*) AS 'number of students'
FROM linkedinmoodle.student_department
GROUP BY gpa_range
ORDER BY gpa_range DESC;

-- Find the distribution of instructor ranks
SELECT instructor_rank AS 'rank', COUNT(*) AS 'number of instructor'
FROM linkedinmoodle.users
WHERE instructor_flag = 1
GROUP BY instructor_rank;

-- Find the distribution of laguages that users speak
SELECT language_name, COUNT(*) AS number_of_speaker
FROM linkedinmoodle.languages
GROUP BY language_name
ORDER BY number_of_speaker DESC;


-- 2 TABLE
-- Find the skills' upvote number for given user
SELECT US.user_id, US.skill, COUNT(ES.endorsed_by_id) AS upvote
FROM linkedinmoodle.user_skills AS US
LEFT JOIN linkedinmoodle.endorse_skills AS ES
ON US.user_id = ES.user_id AND US.skill = ES.skill
WHERE US.user_id = 'ekilisci'
GROUP BY US.user_id, US.skill
ORDER BY upvote DESC;

-- Find the number of graduated students each school has
SELECT O.organization_name, COUNT(*) AS number_of_gtraduated_students
FROM linkedinmoodle.student_department AS SD
JOIN linkedinmoodle.organizations  AS O
ON SD.school_id = O.organization_id
WHERE graduation_date IS NOT NULL
GROUP BY O.organization_name
ORDER BY number_of_gtraduated_students DESC;

-- Find the number of active employees each company has
SELECT O.organization_name, COUNT(*) AS number_of_employee
FROM linkedinmoodle.works_for AS WF
JOIN linkedinmoodle.organizations AS O
ON WF.company_id = O.organization_id
WHERE WF.end_date IS NULL
GROUP BY O.organization_name
ORDER BY number_of_employee DESC;


-- 3 TABLE
-- Find the average grades that a given student has taken from all assignments in each section
SELECT U.first_name, U.last_name, CONCAT(course, ' ', section_year, ' ', section_semester ) AS section, AVG(SU.grade) AS average_grade
FROM linkedinmoodle.users AS U
JOIN linkedinmoodle.submit AS SU
ON U.user_id = SU.student_id
JOIN linkedinmoodle.sections AS S
ON SU.section_id = S.section_id
WHERE U.user_id = 'aderden'
GROUP BY SU.section_id;

-- Find all the sections that instructed by a given instructor
SELECT U.first_name, U.last_name, CONCAT(S.course, ' ', S.section_year, ' ', S.section_semester ) AS section
FROM linkedinmoodle.users AS U
JOIN linkedinmoodle.section_instructor AS SI
ON U.user_id = SI.instructor_id
JOIN linkedinmoodle.sections AS S
ON SI.section_id = S.section_id
WHERE U.user_id = 'bbass';

-- Find all the sections that are offered by a given students department
SELECT S.course, S.section_year, S.section_semester, S.creator_instructor
FROM linkedinmoodle.student_department AS SD
JOIN linkedinmoodle.courses AS C
ON SD.school_id = C.school_id AND SD.department = C.department
JOIN linkedinmoodle.sections AS S
ON C.school_id = S.school_id AND C.department = S.department AND C.course = S.course
WHERE SD.student_id = 'abudakci'
ORDER BY S.section_year DESC, S.section_semester;

-- 4 TABLE
-- Find the all followers of a given account
SELECT A.account_name
FROM linkedinmoodle.follow AS F
JOIN (
SELECT account_id, CONCAT(first_name , ' ' , last_name) AS account_name
FROM linkedinmoodle.users
UNION
SELECT account_id, organization_name AS account_name
FROM linkedinmoodle.organizations
UNION
SELECT account_id, CONCAT(course, ' ', section_year, ' ', section_semester ) AS account_name
FROM linkedinmoodle.sections ) AS A
ON F.follower_id = A.account_id
WHERE F.following_id = 5100;

-- Find the number of working students in companies for each school
SELECT S.organization_name AS school, C.organization_name AS company, COUNT(*) AS number_of_students_working
FROM linkedinmoodle.organizations AS S 
JOIN linkedinmoodle.organizations AS C
JOIN (
	SELECT SD.school_id AS school_id, WF.company_id AS company_id
	FROM linkedinmoodle.users AS U
	JOIN linkedinmoodle.student_department AS SD
	ON U.user_id = SD.student_id
	JOIN linkedinmoodle.works_for AS WF
	ON U.user_id = WF.employee_id
	WHERE SD.graduation_date IS NULL AND WF.end_date IS NULL) AS SW
ON S.organization_id = SW.school_id AND C.organization_id = SW.company_id
GROUP BY school, company
ORDER BY number_of_students_working DESC;

-- Find all the grades of assignments that students have taken from given section
SELECT U.first_name, U.last_name, A.title, SU.grade
FROM linkedinmoodle.sections AS S
JOIN linkedinmoodle.assignment AS A
ON S.section_id = A.section_id
JOIN linkedinmoodle.submit AS SU
ON A.section_id = SU.section_id AND A.title = SU.title
JOIN linkedinmoodle.users AS U
ON SU.student_id = U.user_id
WHERE S.section_id = 812;


-- 5 TABLE
-- Find the accounts that liked the given post
SELECT AA.account_name
FROM linkedinmoodle.shared_items AS S
JOIN linkedinmoodle.likes AS L
ON S.shared_item_id = L.shared_item_id
JOIN (
	SELECT A.account_id, A.account_name
	FROM (SELECT account_id, CONCAT(first_name , ' ' , last_name) AS account_name
		FROM linkedinmoodle.users
		UNION
		SELECT account_id, organization_name AS account_name
		FROM linkedinmoodle.organizations
		UNION
		SELECT account_id, CONCAT(course, ' ', section_year, ' ', section_semester ) AS account_name
		FROM linkedinmoodle.sections ) AS A) AS AA
ON L.account_id = AA.account_id
WHERE S.shared_item_id = 130;


-- 8 TABLE
-- Find the posts and comments that shared by accounts that followed by a given user
SELECT AA.account_name, S.content, S.item_type, S.send_time, P.media_type, P.media_url, C.commented_item_id
FROM linkedinmoodle.users AS U 
JOIN linkedinmoodle.follow AS F 
ON U.account_id = F.follower_id
JOIN linkedinmoodle.shared_items AS S
ON F.following_id = S.account_id
LEFT JOIN linkedinmoodle.posts AS P
ON S.shared_item_id = P.shared_item_id
LEFT JOIN linkedinmoodle.comments AS C
ON S.shared_item_id = C.shared_item_id
JOIN (
	SELECT A.account_id, A.account_name
	FROM (SELECT account_id, CONCAT(first_name , ' ' , last_name) AS account_name
		FROM linkedinmoodle.users
		UNION
		SELECT account_id, organization_name AS account_name
		FROM linkedinmoodle.organizations
		UNION
		SELECT account_id, CONCAT(course, ' ', section_year, ' ', section_semester ) AS account_name
		FROM linkedinmoodle.sections ) AS A) AS AA
ON S.account_id = AA.account_id
WHERE U.user_id = 'aturdo'  
ORDER BY S.send_time DESC;
