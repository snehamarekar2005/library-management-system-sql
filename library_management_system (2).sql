-- ============================================================
-- LIBRARY MANAGEMENT SYSTEM USING SQL
-- ============================================================
-- This script covers:
--   1. Table creation (books, members, book_issues)
--   2. Sample data insertion
--   3. CRUD operations (Create, Read, Update, Delete)
--   4. Real-world report queries
-- Written for MySQL syntax (AUTO_INCREMENT, ENUM, CURDATE()).
-- ============================================================


-- ============================================================
-- SECTION 1: CREATE TABLES
-- ============================================================

DROP TABLE IF EXISTS book_issues;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS members;

-- 1. Books table
CREATE TABLE books (
    book_id           INT PRIMARY KEY AUTO_INCREMENT,
    title             VARCHAR(100) NOT NULL,
    author            VARCHAR(100),
    category          VARCHAR(50),
    total_copies      INT NOT NULL DEFAULT 0,
    available_copies  INT NOT NULL DEFAULT 0,
    CHECK (available_copies >= 0),
    CHECK (available_copies <= total_copies)
);

-- 2. Members table
CREATE TABLE members (
    member_id   INT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    join_date   DATE NOT NULL,
    status      ENUM('active', 'inactive') DEFAULT 'active'
);

-- 3. Book Issues table (the "transactions" table)
CREATE TABLE book_issues (
    issue_id     INT PRIMARY KEY AUTO_INCREMENT,
    book_id      INT NOT NULL,
    member_id    INT NOT NULL,
    issue_date   DATE NOT NULL,
    due_date     DATE NOT NULL,
    return_date  DATE NULL,
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);


-- ============================================================
-- SECTION 2: INSERT SAMPLE DATA
-- ============================================================

INSERT INTO books (title, author, category, total_copies, available_copies) VALUES
('The Alchemist', 'Paulo Coelho', 'Fiction', 5, 3),
('Atomic Habits', 'James Clear', 'Self-Help', 4, 2),
('A Brief History of Time', 'Stephen Hawking', 'Science', 3, 3),
('Introduction to Algorithms', 'Cormen', 'Computer Science', 2, 1),
('Sapiens', 'Yuval Noah Harari', 'History', 4, 4),
('Rich Dad Poor Dad', 'Robert Kiyosaki', 'Finance', 3, 2),
('Wings of Fire', 'A.P.J. Abdul Kalam', 'Biography', 3, 1),
('The Silent Patient', 'Alex Michaelides', 'Thriller', 2, 2);

INSERT INTO members (name, email, join_date, status) VALUES
('Rohan Sharma', 'rohan.sharma@email.com', '2024-01-10', 'active'),
('Priya Patil', 'priya.patil@email.com', '2024-02-15', 'active'),
('Aman Verma', 'aman.verma@email.com', '2024-03-05', 'active'),
('Sneha Kulkarni', 'sneha.kulkarni@email.com', '2024-04-20', 'inactive'),
('Rahul Deshmukh', 'rahul.deshmukh@email.com', '2024-05-11', 'active'),
('Kavita Joshi', 'kavita.joshi@email.com', '2024-06-01', 'active');

-- issue_date / due_date / return_date chosen so we get a mix of:
-- returned on time, currently issued, and OVERDUE records
INSERT INTO book_issues (book_id, member_id, issue_date, due_date, return_date) VALUES
(1, 1, '2024-06-01', '2024-06-15', '2024-06-14'),  -- returned on time
(1, 2, '2024-06-20', '2024-07-04', NULL),           -- overdue (never returned, past due date)
(2, 3, '2024-07-01', '2024-07-15', '2024-07-16'),  -- returned late
(4, 1, '2024-07-10', '2024-07-24', NULL),           -- overdue
(6, 2, '2024-07-15', '2024-07-29', NULL),           -- overdue
(1, 3, '2024-07-20', '2024-08-03', NULL),           -- currently issued, not yet due
(7, 5, '2024-05-01', '2024-05-15', '2024-05-13'),  -- returned on time
(7, 6, '2024-06-10', '2024-06-24', NULL),           -- overdue
(2, 4, '2024-04-01', '2024-04-15', '2024-04-14');  -- returned on time


-- ============================================================
-- SECTION 3: CRUD OPERATIONS
-- ============================================================

-- ---------- CREATE ----------

-- 3.1 Add a new book
INSERT INTO books (title, author, category, total_copies, available_copies)
VALUES ('Deep Work', 'Cal Newport', 'Self-Help', 3, 3);

-- 3.2 Add a new member
INSERT INTO members (name, email, join_date, status)
VALUES ('Neha Pawar', 'neha.pawar@email.com', CURDATE(), 'active');

-- ---------- READ ----------

-- 3.3 View all books
SELECT * FROM books;

-- 3.4 View all active members
SELECT * FROM members WHERE status = 'active';

-- ---------- UPDATE ----------

-- 3.5 Update book quantities (e.g. library bought 2 more copies of book_id 4)
UPDATE books
SET total_copies = total_copies + 2,
    available_copies = available_copies + 2
WHERE book_id = 4;

-- 3.6 Issue a book to a member (two steps: log the issue + reduce available copies)
-- Step A: check availability first
SELECT available_copies FROM books WHERE book_id = 3;

-- Step B: only issue if available_copies > 0
INSERT INTO book_issues (book_id, member_id, issue_date, due_date, return_date)
SELECT 3, 4, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), NULL
WHERE (SELECT available_copies FROM books WHERE book_id = 3) > 0;

UPDATE books
SET available_copies = available_copies - 1
WHERE book_id = 3 AND available_copies > 0;

-- 3.7 Return a book (mark return_date + restore available copy)
UPDATE book_issues
SET return_date = CURDATE()
WHERE issue_id = 2;   -- pick the specific issue_id being returned

UPDATE books
SET available_copies = available_copies + 1
WHERE book_id = (SELECT book_id FROM book_issues WHERE issue_id = 2);

-- ---------- DELETE ----------

-- 3.8 Delete a member -- only allowed if they have NO currently issued (unreturned) books
DELETE FROM members
WHERE member_id = 4
AND member_id NOT IN (
    SELECT member_id FROM book_issues WHERE return_date IS NULL
);

-- 3.9 Delete a book -- only allowed if all its copies are currently in the library
-- (i.e. none of its copies are out on loan)
DELETE FROM books
WHERE book_id = 5
AND available_copies = total_copies;


-- ============================================================
-- SECTION 4: REAL-WORLD REPORT QUERIES
-- ============================================================

-- 4.1 How many books are available right now? (total available copies, library-wide)
SELECT SUM(available_copies) AS total_available_copies
FROM books;

-- 4.1b Availability broken down per book
SELECT title, available_copies, total_copies
FROM books
ORDER BY available_copies DESC;

-- 4.2 Which member has borrowed which book? (full issue history)
SELECT
    m.name        AS member_name,
    b.title       AS book_title,
    bi.issue_date,
    bi.due_date,
    bi.return_date
FROM book_issues bi
JOIN members m ON bi.member_id = m.member_id
JOIN books b   ON bi.book_id   = b.book_id
ORDER BY bi.issue_date DESC;

-- 4.3 Which books are overdue? (not returned AND past due date)
SELECT
    m.name        AS member_name,
    b.title       AS book_title,
    bi.due_date,
    DATEDIFF(CURDATE(), bi.due_date) AS days_overdue
FROM book_issues bi
JOIN members m ON bi.member_id = m.member_id
JOIN books b   ON bi.book_id   = b.book_id
WHERE bi.return_date IS NULL
AND bi.due_date < CURDATE()
ORDER BY days_overdue DESC;

-- 4.4 Top 5 most borrowed books
SELECT
    b.title,
    COUNT(bi.issue_id) AS times_borrowed
FROM book_issues bi
JOIN books b ON bi.book_id = b.book_id
GROUP BY b.book_id, b.title
ORDER BY times_borrowed DESC
LIMIT 5;

-- 4.5 Bonus: members who currently have a book out (not yet returned)
SELECT
    m.name AS member_name,
    b.title AS book_title,
    bi.due_date
FROM book_issues bi
JOIN members m ON bi.member_id = m.member_id
JOIN books b   ON bi.book_id   = b.book_id
WHERE bi.return_date IS NULL;
