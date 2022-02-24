CREATE SCHEMA IF NOT EXISTS linkedinmoodle;
USE linkedinmoodle;

CREATE TABLE  linkedinmoodle.accounts (
account_id INTEGER AUTO_INCREMENT NOT NULL,
account_type ENUM('USER','ORGANIZATION','SECTION') CHECK (account_type IN ('USER','ORGANIZATION','SECTION')),
PRIMARY KEY(account_id));

CREATE TABLE  linkedinmoodle.users (
user_id VARCHAR(32) NOT NULL,
first_name VARCHAR(48) NOT NULL,
last_name VARCHAR(48) NOT NULL,
email VARCHAR(64) NOT NULL,
password_hash CHAR(128) NOT NULL,
birth_date DATE NOT NULL,
gender CHAR(1) NOT NULL CHECK (gender IN ('F','M')),
visibility ENUM('ALL','CONTACTS','NONE') CHECK (visibility IN ('ALL','CONTACTS','NONE')),
about TEXT,
website VARCHAR(64),
city VARCHAR(48) NOT NULL,
country VARCHAR(48) NOT NULL,
state VARCHAR(48),
created_time TIMESTAMP DEFAULT NOW(),
account_id INTEGER NOT NULL,
employee_flag BOOLEAN DEFAULT 0,
instructor_flag BOOLEAN DEFAULT 0,
instructor_rank ENUM('RESEARCH ASSISTANT','LECTURER','ASSISTANT PROFESSOR','ASSOCIATE PROFESSOR','FULL PROFESSOR','UNSPECIFIED') CHECK (instructor_rank IN ('RESEARCH ASSISTANT','LECTURER','ASSISTANT PROFESSOR','ASSOCIATE PROFESSOR','FULL PROFESSOR', 'UNSPECIFIED') OR instructor_rank IS NULL),
student_flag BOOLEAN DEFAULT 0,
PRIMARY KEY (user_id),
FOREIGN KEY(account_id) REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE RESTRICT,
UNIQUE(account_id),
UNIQUE (email),
CONSTRAINT instructor_rank_CHK CHECK ( (instructor_flag = TRUE AND instructor_rank IS NOT NULL) OR (instructor_flag = FALSE AND instructor_rank IS NULL) )
);

CREATE TABLE linkedinmoodle.languages(
user_id VARCHAR(32) NOT NULL, 
language_name VARCHAR(32) NOT NULL,
PRIMARY KEY(user_id, language_name),
FOREIGN KEY(user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.certificates(
user_id VARCHAR(32) NOT NULL, 
certificate VARCHAR(64) NOT NULL,
PRIMARY KEY(user_id, certificate),
FOREIGN KEY(user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.user_skills(
user_id VARCHAR(32) NOT NULL, 
skill VARCHAR(64) NOT NULL,
PRIMARY KEY(user_id, skill),
FOREIGN KEY(user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.endorse_skills(
user_id VARCHAR(32) NOT NULL,
skill VARCHAR(64) NOT NULL,
endorsed_by_id VARCHAR(32) NOT NULL,
PRIMARY KEY(user_id, skill, endorsed_by_id),
FOREIGN KEY(endorsed_by_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(user_id, skill) REFERENCES user_skills(user_id, skill) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.connections(
user_id VARCHAR(32) NOT NULL, 
connection_id VARCHAR(32) NOT NULL,
connection_time TIMESTAMP DEFAULT NOW(),
PRIMARY KEY(user_id, connection_id),
FOREIGN KEY(user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.connection_requests(
sender_id VARCHAR(32) NOT NULL, 
receiver_id VARCHAR(32) NOT NULL,
send_time TIMESTAMP DEFAULT NOW(),
request_status ENUM('PENDING','ACCEPTED','REJECTED') CHECK (request_status IN ('PENDING','ACCEPTED','REJECTED')),
PRIMARY KEY(sender_id, receiver_id),
FOREIGN KEY(sender_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(receiver_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.reference_to(
user_id VARCHAR(32) NOT NULL, 
reference_to_id VARCHAR(32) NOT NULL,
PRIMARY KEY(user_id, reference_to_id),
FOREIGN KEY(user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(reference_to_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.messages(
message_id INTEGER AUTO_INCREMENT NOT NULL,
sender_id VARCHAR(32) NOT NULL, 
receiver_id VARCHAR(32) NOT NULL,
content TEXT NOT NULL,
send_time TIMESTAMP DEFAULT NOW(),
PRIMARY KEY(message_id),
FOREIGN KEY(sender_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(receiver_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE  linkedinmoodle.organizations (
organization_id VARCHAR(32) NOT NULL,
organization_name VARCHAR(48) NOT NULL,
organization_type ENUM('COMPANY','SCHOOL') NOT NULL CHECK (organization_type IN ('COMPANY','SCHOOL')),
creator_id VARCHAR(32) NOT NULL,
about TEXT,
website VARCHAR(64),
city VARCHAR(48) NOT NULL,
country VARCHAR(48) NOT NULL,
state VARCHAR(48),
created_time TIMESTAMP DEFAULT NOW(),
account_id INTEGER NOT NULL,
PRIMARY KEY (organization_id),
FOREIGN KEY(account_id) REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE RESTRICT,
FOREIGN KEY(creator_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
UNIQUE(account_id)
);

CREATE TABLE linkedinmoodle.organization_administration(
organization_id VARCHAR(32) NOT NULL,
user_id VARCHAR(32) NOT NULL, 
PRIMARY KEY(organization_id, user_id),
FOREIGN KEY(user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
FOREIGN KEY(organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.companies(
organization_id VARCHAR(32) NOT NULL,
sector VARCHAR(64),
PRIMARY KEY(organization_id),
FOREIGN KEY(organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE linkedinmoodle.works_for(
employee_id VARCHAR(32) NOT NULL, 
company_id VARCHAR(32) NOT NULL,
start_date DATE NOT NULL,
working_role VARCHAR(32) NOT NULL,
working_type VARCHAR(32) NOT NULL,
end_date DATE,
PRIMARY KEY(employee_id, company_id, start_date),
FOREIGN KEY(employee_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(company_id) REFERENCES companies(organization_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE linkedinmoodle.job_adverts(
company_id VARCHAR(32) NOT NULL,
advert_id INTEGER NOT NULL,
title VARCHAR(128) NOT NULL,
description TEXT NOT NULL,
city VARCHAR(48) NOT NULL,
country VARCHAR(48) NOT NULL,
state VARCHAR(48),
publish_time TIMESTAMP DEFAULT NOW(),
current_status ENUM('OPEN','CLOSED') NOT NULL DEFAULT('OPEN') CHECK (current_status IN ('OPEN','CLOSED')),
PRIMARY KEY(company_id, advert_id),
FOREIGN KEY(company_id) REFERENCES companies(organization_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.job_application(
user_id VARCHAR(32) NOT NULL,
company_id VARCHAR(32) NOT NULL,
advert_id INTEGER NOT NULL,
application_time TIMESTAMP DEFAULT NOW(),
PRIMARY KEY(user_id, company_id, advert_id),
FOREIGN KEY(user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
FOREIGN KEY(company_id, advert_id) REFERENCES job_adverts(company_id, advert_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.schools(
organization_id VARCHAR(32) NOT NULL,
PRIMARY KEY(organization_id),
FOREIGN KEY(organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE linkedinmoodle.departments(
school_id VARCHAR(32) NOT NULL,
department VARCHAR(64) NOT NULL,
PRIMARY KEY(school_id, department),
FOREIGN KEY(school_id) REFERENCES schools(organization_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE linkedinmoodle.student_department(
student_id VARCHAR(32) NOT NULL,
school_id VARCHAR(32) NOT NULL,
department VARCHAR(64) NOT NULL,
student_no VARCHAR(16) NOT NULL,
start_date DATE NOT NULL,
graduation_date DATE,
gpa DECIMAL(3,2),
PRIMARY KEY(student_id, school_id, department),
FOREIGN KEY(student_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(school_id, department) REFERENCES departments(school_id, department) ON UPDATE CASCADE ON DELETE RESTRICT,
CONSTRAINT gpa_CHK CHECK (gpa >= 0 AND gpa <= 4)
);

CREATE TABLE linkedinmoodle.instructor_department(
instructor_id VARCHAR(32) NOT NULL,
school_id VARCHAR(32) NOT NULL,
department VARCHAR(64) NOT NULL,
start_date DATE NOT NULL,
end_date DATE,
PRIMARY KEY(instructor_id, school_id, department),
FOREIGN KEY(instructor_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(school_id, department) REFERENCES departments(school_id, department) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE linkedinmoodle.courses(
school_id VARCHAR(32) NOT NULL,
department VARCHAR(64) NOT NULL,
course VARCHAR(64) NOT NULL,
PRIMARY KEY(school_id, department, course),
FOREIGN KEY(school_id, department) REFERENCES departments(school_id, department) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE linkedinmoodle.sections(
section_id INTEGER AUTO_INCREMENT,
school_id VARCHAR(32) NOT NULL,
department VARCHAR(64) NOT NULL,
course VARCHAR(64) NOT NULL,
section_year INT4 NOT NULL,
section_semester ENUM('FALL','SPRING', 'SUMMER') NOT NULL CHECK (section_semester IN ('FALL','SPRING', 'SUMMER')),
enrollment_password VARCHAR(32) NOT NULL,
creator_instructor VARCHAR(32) NOT NULL,
account_id INTEGER NOT NULL,
PRIMARY KEY(section_id),
FOREIGN KEY(creator_instructor) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
FOREIGN KEY(school_id, department, course) REFERENCES courses(school_id, department, course) ON UPDATE CASCADE ON DELETE RESTRICT,
FOREIGN KEY(account_id) REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE linkedinmoodle.section_instructor(
section_id INTEGER NOT NULL,
instructor_id VARCHAR(32) NOT NULL,
PRIMARY KEY(section_id, instructor_id),
FOREIGN KEY(instructor_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
FOREIGN KEY(section_id) REFERENCES sections(section_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.enroll(
student_id VARCHAR(32) NOT NULL,
section_id INTEGER NOT NULL,
PRIMARY KEY(student_id, section_id),
FOREIGN KEY(student_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(section_id) REFERENCES sections(section_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE linkedinmoodle.assignment(
section_id INTEGER NOT NULL,
title VARCHAR(64) NOT NULL,
content TEXT NOT NULL,
deadline TIMESTAMP NOT NULL,
PRIMARY KEY(section_id, title),
FOREIGN KEY(section_id) REFERENCES sections(section_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.submit(
student_id VARCHAR(32) NOT NULL,
section_id INTEGER NOT NULL,
title VARCHAR(64) NOT NULL,
submited_file VARCHAR(255),
submitted_time TIMESTAMP,
grade DECIMAL,
PRIMARY KEY(student_id, section_id, title),
FOREIGN KEY(student_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(section_id, title) REFERENCES assignment(section_id, title) ON UPDATE CASCADE ON DELETE CASCADE,
CONSTRAINT assignment_grade_CHK CHECK (grade >= 0 AND grade <= 100)
);

CREATE TABLE linkedinmoodle.follow(
follower_id INTEGER NOT NULL,
following_id INTEGER NOT NULL,
follow_time TIMESTAMP DEFAULT NOW(),
PRIMARY KEY(follower_id, following_id),
FOREIGN KEY(follower_id) REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(following_id) REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.shared_items(
shared_item_id INTEGER AUTO_INCREMENT,
account_id INTEGER NOT NULL,
content TEXT NOT NULL,
send_time TIMESTAMP DEFAULT NOW(),
item_type ENUM('POST','COMMENT') NOT NULL CHECK (item_type IN ('POST','COMMENT')),
PRIMARY KEY(shared_item_id),
FOREIGN KEY(account_id) REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.posts(
shared_item_id INTEGER NOT NULL,
media_type ENUM('IMAGE','VIDEO','DOCUMENT') CHECK (media_type IN ('IMAGE','VIDEO','DOCUMENT') OR media_type IS NULL),
media_url VARCHAR(255),
PRIMARY KEY(shared_item_id),
FOREIGN KEY(shared_item_id) REFERENCES shared_items(shared_item_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.comments(
shared_item_id INTEGER NOT NULL,
commented_item_id INTEGER NOT NULL,
PRIMARY KEY(shared_item_id),
FOREIGN KEY(shared_item_id) REFERENCES shared_items(shared_item_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(commented_item_id) REFERENCES shared_items(shared_item_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE linkedinmoodle.likes(
account_id INTEGER NOT NULL,
shared_item_id INTEGER NOT NULL,
PRIMARY KEY(account_id, shared_item_id),
FOREIGN KEY(shared_item_id) REFERENCES shared_items(shared_item_id) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY(account_id) REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE CASCADE
);