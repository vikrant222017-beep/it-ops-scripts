-- ============================================
-- Azure AD User Audit & Access Report
-- Author: Vikrant Verma
-- Description: Track user access, MFA status,
-- and inactive accounts for security audits
-- ============================================

CREATE TABLE AD_Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(100),
    Email VARCHAR(100),
    Department VARCHAR(50),
    JobTitle VARCHAR(100),
    MFAEnabled BOOLEAN DEFAULT FALSE,
    AccountStatus VARCHAR(20) DEFAULT 'Active',
    LastLoginDate DATETIME,
    CreatedDate DATETIME,
    LicenseType VARCHAR(50)
);

-- Users with MFA not enabled (security risk)
SELECT FullName, Email, Department, JobTitle
FROM AD_Users
WHERE MFAEnabled = FALSE
AND AccountStatus = 'Active'
ORDER BY Department;

-- Inactive accounts (no login in 90 days)
SELECT FullName, Email, LastLoginDate,
    DATEDIFF(NOW(), LastLoginDate) AS DaysInactive
FROM AD_Users
WHERE LastLoginDate < DATE_SUB(NOW(), INTERVAL 90 DAY)
AND AccountStatus = 'Active'
ORDER BY DaysInactive DESC;

-- License usage by department
SELECT Department,
    LicenseType,
    COUNT(*) AS UserCount
FROM AD_Users
WHERE AccountStatus = 'Active'
GROUP BY Department, LicenseType
ORDER BY Department;
