-- Create the database
CREATE DATABASE week4assignment;

-- Use the database
USE week4assignment;


-- Create the employees table
CREATE TABLE employees (
    EmpID INT PRIMARY KEY,
    FullName VARCHAR(50),
    Salary INT
);

-- Insert the given data
INSERT INTO employees (EmpID, FullName, Salary) VALUES
(1, 'Ali', 120000),
(2, 'Asser', 110000),
(3, 'Mona', 100000),
(4, 'Fatma', 90000),
(5, 'Gehad', 80000),
(6, 'Ahmed', 70000);

--  Check the table content
SELECT * FROM employees;

------------------------ Part 1 -----------------------------------

-- Create logins and users
USE master;
-- Login
CREATE LOGIN user_public WITH PASSWORD = 'Public';
CREATE LOGIN user_admin WITH PASSWORD = 'Admin';

USE week4assignment;
-- Users
CREATE USER general FOR LOGIN user_public;
CREATE USER admin1 FOR LOGIN user_admin;

-- Create roles 
CREATE ROLE public_role;
CREATE ROLE admin_role;

ALTER ROLE public_role ADD MEMBER general;
ALTER ROLE admin_role ADD MEMBER admin1;


-- Grant only limited access to public_role and full access to admin_role
CREATE VIEW V_EMP_ID_N AS
SELECT EmpID, FullName
FROM employees;

CREATE VIEW V_EMP_ID_S AS
SELECT EmpID, Salary
FROM employees;

GRANT SELECT ON V_EMP_ID_N TO public_role;
GRANT SELECT ON V_EMP_ID_S TO public_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.employees TO admin_role;


-- Test
-- admin1 Test
-- All not denied
EXECUTE AS USER = 'admin1';
SELECT * FROM dbo.employees;

INSERT INTO dbo.employees (EmpID, FullName, Salary) VALUES
(7, 'Mohammad', 60000);
SELECT * FROM dbo.employees;

UPDATE dbo.employees 
SET FullName = 'Mohamed'
WHERE EmpID = 7;
SELECT * FROM dbo.employees;

DELETE FROM dbo.employees
WHERE EmpID = 7;
SELECT * FROM dbo.employees;

REVERT;

--------------------------
-- general test
-- denied
EXECUTE AS USER = 'general';
SELECT * FROM dbo.employees;
REVERT;

-- denied
EXECUTE AS USER = 'general';
INSERT INTO dbo.employees (EmpID, FullName, Salary) VALUES
(7, 'Mohammad', 60000);
SELECT * FROM dbo.employees;
REVERT;

-- denied
EXECUTE AS USER = 'general';
UPDATE dbo.employees 
SET FullName = 'Mohamed'
WHERE EmpID = 7;
SELECT * FROM dbo.employees;
REVERT;

-- denied
EXECUTE AS USER = 'general';
DELETE FROM dbo.employees
WHERE EmpID = 7;
REVERT;

-- denied
EXECUTE AS USER = 'general';
SELECT * FROM dbo.employees;
REVERT;

-- Not denied
EXECUTE AS USER = 'general';
SELECT * FROM V_EMP_ID_N;
SELECT * FROM V_EMP_ID_S;
REVERT;

-- THE TEST CASE "PROBLEM"
EXECUTE AS USER = 'general';
SELECT 
    n.EmpID,
    n.FullName,
    s.Salary
FROM V_EMP_ID_N AS n
JOIN V_EMP_ID_S AS s
    ON n.EmpID = s.EmpID;

	---Second way to attack---
SELECT FullName FROM employees ORDER BY Salary DESC;
SELECT Salary FROM employees ORDER BY Salary DESC;
REVERT;


-- To solve this PROBLEM we can deny creating views or use random IDs
-- We will apply random IDs and deny creating views give access to the admin on the mapping and shuffle the orders
CREATE TABLE PublicNames (
  PublicEmpID uniqueidentifier PRIMARY KEY DEFAULT NEWID(),
  FullName varchar(100)
);

CREATE TABLE PublicSalaries (
  PublicSalaryID uniqueidentifier PRIMARY KEY DEFAULT NEWID(),
  Salary int
);

CREATE TABLE AdminMap (
  EmpID int PRIMARY KEY,
  PublicNameID uniqueidentifier REFERENCES PublicNames(PublicEmpID),
  PublicSalaryID uniqueidentifier REFERENCES PublicSalaries(PublicSalaryID)
);
Revert;

INSERT INTO PublicNames(FullName)
SELECT FullName FROM employees;

-- note: order is independent
INSERT INTO PublicSalaries(Salary)
SELECT Salary FROM employees;

INSERT INTO AdminMap(EmpID, PublicNameID, PublicSalaryID)
SELECT
  e.EmpID,
  pn.PublicEmpID,
  ps.PublicSalaryID
FROM employees AS e
JOIN PublicNames AS pn ON pn.FullName = e.FullName
JOIN PublicSalaries AS ps ON ps.Salary = e.Salary;

SELECT * FROM employees;
SELECT * FROM PublicNames;
SELECT * FROM PublicSalaries;
SELECT * FROM AdminMap;

-- View for names (no IDs, randomized order)
CREATE VIEW V_Public_N AS
SELECT FullName FROM PublicNames;

SELECT * FROM V_Public_N;

-- View for salaries (no IDs, randomized order)
CREATE  VIEW V_Public_S AS
SELECT Salary FROM PublicSalaries;

SELECT * FROM V_Public_S;


CREATE VIEW V_Admin_NS AS
SELECT e.EmpID, e.FullName FROM employees e;

SELECT * FROM V_Admin_NS;
--part 3--
---solved AdminFullMap---
CREATE VIEW V_AdminFullMap AS
SELECT 
    e.EmpID,
    e.FullName,
    e.Salary,
    a.PublicNameID,
    a.PublicSalaryID
FROM employees AS e
JOIN AdminMap AS a
    ON e.EmpID = a.EmpID;
	---second way to attack---
	



SELECT * FROM V_AdminFullMap;

GRANT SELECT ON V_Public_N TO public_role;
GRANT SELECT ON V_Public_S TO public_role;

DENY  SELECT ON AdminMap TO public_role;
DENY  SELECT ON V_AdminFullMap TO public_role;
DENY  SELECT ON employees TO public_role;

DENY VIEW DEFINITION ON AdminMap TO public_role;
DENY VIEW DEFINITION ON V_AdminFullMap TO public_role;
DENY VIEW DEFINITION ON employees TO public_role;

DENY CREATE VIEW TO public_role;

-- Admins: can see the resolved mapping
GRANT SELECT ON V_Admin_NS TO admin_role;
GRANT SELECT ON AdminMap TO admin_role;
GRANT SELECT ON V_AdminFullMap TO admin_role;


-- public
--accepted
EXECUTE AS USER = 'general';
SELECT * FROM V_Public_S;  
REVERT;

EXECUTE AS USER = 'general';
SELECT * FROM V_Public_N;
REVERT;

-- denied
EXECUTE AS USER = 'general';
SELECT * FROM employees;  
REVERT;

EXECUTE AS USER = 'general';
SELECT * FROM V_Admin_NS;  
REVERT;

EXECUTE AS USER = 'general';
SELECT * FROM V_AdminFullMap;  
REVERT;

--------------------------
--admin1
-- accepted
EXECUTE AS USER = 'admin1';
SELECT * FROM V_Admin_NS;  
REVERT;

EXECUTE AS USER = 'admin1';
SELECT * FROM AdminMap;  
REVERT;

EXECUTE AS USER = 'admin1';
SELECT * FROM V_AdminFullMap;  
REVERT;

------------------------ Part 2 -----------------------------------
-- Create the roles and the users 
CREATE ROLE read_onlyX;
CREATE ROLE insert_onlyX;

USE master;
CREATE LOGIN ur WITH PASSWORD = 'read';
CREATE LOGIN uin WITH PASSWORD = 'insert';

USE week4assignment;
CREATE USER read_user FOR LOGIN ur;
CREATE USER insert_user FOR LOGIN uin;

ALTER ROLE read_onlyX ADD MEMBER read_user;
ALTER ROLE insert_onlyX ADD MEMBER insert_user;

-- Enforce least privilege
-- Grant minimal access
-- read_onlyX can only view data
GRANT SELECT ON dbo.employees TO read_onlyX;

-- insert_onlyX can only insert new rows and view data
GRANT SELECT, INSERT ON dbo.employees TO insert_onlyX;

-- Deny other operations to enforce least privilege
DENY UPDATE, DELETE ON employees TO read_onlyX;
DENY UPDATE, DELETE ON employees TO insert_onlyX;

-- Test
-- The insert only user
-- accepted
EXECUTE AS USER = 'insert_user';
INSERT INTO employees (EmpID, FullName, Salary) VALUES
(7, 'Mohammad', 60000);
REVERT;

EXECUTE AS USER = 'insert_user';
SELECT * FROM employees;  
REVERT;

-- denied
EXECUTE AS USER = 'insert_user';
UPDATE employees SET Salary = 60000 
WHERE EmpID = 1;
REVERT;

EXECUTE AS USER = 'insert_user';
DELETE FROM employees 
WHERE EmpID = 1;
REVERT;

-- the read only user
-- accepted
EXECUTE AS USER = 'read_user';
SELECT * FROM employees;  
REVERT;

-- denied
EXECUTE AS USER = 'read_user';
UPDATE employees SET Salary = 10000 
WHERE EmpID = 7;
REVERT;

EXECUTE AS USER = 'read_user';
INSERT INTO employees (EmpID, FullName, Salary) VALUES
(8, 'Amr', 1000);
REVERT;

EXECUTE AS USER = 'read_user';
DELETE FROM employees 
WHERE EmpID = 1;
REVERT;

-- For a less privilege
REVOKE SELECT ON employees FROM insert_onlyX;

-- Test
-- accepted
EXECUTE AS USER = 'insert_user';
INSERT INTO employees (EmpID, FullName, Salary) VALUES
(8, 'Amr', 10000);
REVERT;

-- denied
EXECUTE AS USER = 'insert_user';
SELECT * FROM employees;  
REVERT;

-- View the final updates from insert user
SELECT * FROM employees;
---------Back to the original employees table------------ 
DELETE FROM employees 
WHERE EmpID = 7 or EmpID = 8;
SELECT * FROM employees; 
--------------------------------------------------------------------------------------------------------------
-- power user, Role Hierarchy & Composite Role (role inheritance)
CREATE ROLE power_user;

EXEC sp_addrolemember 'read_onlyX', 'power_user';
EXEC sp_addrolemember 'insert_onlyX', 'power_user';

USE master;
CREATE LOGIN power_user1 WITH PASSWORD = 'power';

USE week4assignment;
CREATE USER power_user1 FOR LOGIN power_user1;
-- same as the sp user to map the read and insert only roles to the power user role
ALTER ROLE power_user ADD MEMBER power_user1;

-- Test
-- accepted
EXECUTE AS USER = 'power_user1';
INSERT INTO dbo.employees VALUES (7, 'Tarek', 50000);
REVERT;

EXECUTE AS USER = 'power_user1';
SELECT * FROM employees;
REVERT;

-- denied
EXECUTE AS USER = 'power_user1';
UPDATE employees SET Salary = 60000 
WHERE EmpID = 1;
REVERT;

EXECUTE AS USER = 'power_user1';
DELETE FROM employees 
WHERE EmpID = 1;
REVERT;

SElECT * FROM employees;
---------Back to the original employees table------------ 
DELETE FROM employees 
WHERE EmpID = 7 or EmpID = 8;
SELECT * FROM employees;  
---------------------------------------------------------

-- REVOKING from insertonlyX and test
REVOKE INSERT ON employees FROM insert_onlyX;

-- denied 
EXECUTE AS USER = 'insert_user';
INSERT INTO employees (EmpID, FullName, Salary) VALUES
(8, 'Amr', 10000);
REVERT;

EXECUTE AS USER = 'power_user1';
SELECT * FROM employees; 
INSERT INTO employees VALUES (8, 'Adham', 10000);
REVERT;

----To Drop Our Problem----(Part3)
revert;

-- 1. Drop weak views
DROP VIEW IF EXISTS V_EMP_ID_N;
DROP VIEW IF EXISTS V_EMP_ID_S;

-- 2. making safe views
CREATE VIEW V_Public_N AS
SELECT FullName FROM PublicNames;

CREATE VIEW V_Public_S AS
SELECT Salary FROM PublicSalaries;

-- 3. اسح
REVOKE SELECT ON V_EMP_ID_N FROM public_role;
REVOKE SELECT ON V_EMP_ID_S FROM public_role;
DENY SELECT ON V_EMP_ID_N TO public_role;
DENY SELECT ON V_EMP_ID_S TO public_role;

-- 4. منح الصلاحيات للـ Views الآمنة
GRANT SELECT ON V_Public_N TO public_role;
GRANT SELECT ON V_Public_S TO public_role;

-- 5. تأكدي أن public_role مافيهوش صلاحية على الجداول الأصلية
DENY SELECT ON employees TO public_role;
DENY SELECT ON AdminMap TO public_role;


EXECUTE AS USER = 'general';
SELECT 
    n.EmpID,
    n.FullName,
    s.Salary
FROM V_EMP_ID_N AS n
JOIN V_EMP_ID_S AS s
    ON n.EmpID = s.EmpID;
---To check which views can general user show--
	USE week4assignment;
SELECT name, type_desc 
FROM sys.objects 
WHERE type = 'V';

revert;

---To check which views can admin1  show---
EXECUTE AS USER = 'admin1';
SELECT name 
FROM sys.objects 
WHERE type = 'V' 
AND HAS_PERMS_BY_NAME(name, 'OBJECT', 'SELECT') = 1;
REVERT;
----part5----------
CREATE TABLE EmployeeDetails (
    EmpID INT PRIMARY KEY,
    Dept VARCHAR(50),
    Title VARCHAR(50),
    Grade INT,
    Bonus DECIMAL(10,2)
);

INSERT INTO EmployeeDetails (EmpID, Dept, Title, Grade, Bonus) VALUES
(1, 'IT', 'Manager', 1, 5000),
(2, 'HR', 'Supervisor', 2, 3000),
(3, 'Finance', 'Analyst', 3, 2000),
(4, 'IT', 'Developer', 2, 4000),
(5, 'HR', 'Assistant', 3, 1500),
(6, 'Finance', 'Clerk', 4, 1000);


SELECT 'Closure Q⁺ contains: Dept, Title, Grade, Bonus' AS Proof;

EXECUTE AS USER = 'general';
SELECT Dept, Title FROM EmployeeDetails;
REVERT;
SELECT 'Query REJECTED: This query can infer sensitive Bonus data through FDs' AS Security_Action;


SELECT Dept FROM EmployeeDetails; 
-- او
SELECT Title FROM EmployeeDetails; 

CREATE VIEW SafeEmployeeView AS
SELECT EmpID, Dept, Title 
FROM EmployeeDetails
WHERE (Dept = 'IT' AND Title != 'Manager') 
   OR (Dept != 'IT');

GRANT SELECT ON SafeEmployeeView TO public_role;

EXECUTE AS USER = 'general';
SELECT * FROM SafeEmployeeView; 
REVERT;

------------------------ Part 6 - Inference via Aggregates ------------------------

CREATE VIEW DepartmentAvgSalary AS
SELECT Dept, AVG(Salary) as AvgSalary, COUNT(*) as EmpCount
FROM employees e
JOIN EmployeeDetails ed ON e.EmpID = ed.EmpID
GROUP BY Dept;

CREATE VIEW OverallAvgSalary AS
SELECT AVG(Salary) as OverallAvg FROM employees;

EXECUTE AS USER = 'general';

SELECT 'Attack: Inferring salary using averages' AS Attack_Scenario;
SELECT * FROM DepartmentAvgSalary;
SELECT * FROM OverallAvgSalary;

REVERT;

CREATE VIEW NoisyDepartmentAvg AS
SELECT 
    Dept,
    AVG(Salary) * (0.95 + (RAND() * 0.1)) as NoisyAvgSalary,
    CASE 
        WHEN COUNT(*) BETWEEN 1 AND 5 THEN '1-5'
        WHEN COUNT(*) BETWEEN 6 AND 10 THEN '6-10' 
        ELSE '10+'
    END as EmpRange
FROM employees e
JOIN EmployeeDetails ed ON e.EmpID = ed.EmpID
GROUP BY Dept;

CREATE VIEW NoisyOverallAvg AS
SELECT 
    AVG(Salary) * (0.97 + (RAND() * 0.06)) as NoisyOverallAvg
FROM employees;

GRANT SELECT ON NoisyDepartmentAvg TO public_role;
GRANT SELECT ON NoisyOverallAvg TO public_role;

DENY SELECT ON DepartmentAvgSalary TO public_role;
DENY SELECT ON OverallAvgSalary TO public_role;
EXECUTE AS USER = 'general';
SELECT 'Testing Randomization protection' AS Test;
SELECT * FROM NoisyDepartmentAvg;
SELECT * FROM NoisyOverallAvg;
REVERT;
SELECT 'Proof that randomization prevents inference:' AS Proof;
SELECT 
    'Actual vs Noisy Averages - Inference is now impossible' AS Comparison;
    
SELECT 
    d.Dept,
    d.AvgSalary as ActualAvg,
    n.NoisyAvgSalary as NoisyAvg,
    ABS(d.AvgSalary - n.NoisyAvgSalary) as Difference
FROM DepartmentAvgSalary d
JOIN NoisyDepartmentAvg n ON d.Dept = n.Dept;

