-- ============================================
-- IT Asset Inventory Management System
-- Author: Vikrant Verma
-- Description: Track and manage IT assets,
-- assignments, and maintenance schedules
-- ============================================

CREATE TABLE Assets (
    AssetID INT PRIMARY KEY AUTO_INCREMENT,
    AssetName VARCHAR(100),
    AssetType VARCHAR(50),
    SerialNumber VARCHAR(100),
    AssignedTo VARCHAR(100),
    Department VARCHAR(50),
    PurchaseDate DATE,
    WarrantyExpiry DATE,
    Status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE MaintenanceLogs (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    AssetID INT,
    MaintenanceDate DATE,
    Description TEXT,
    TechnicianName VARCHAR(100),
    FOREIGN KEY (AssetID) REFERENCES Assets(AssetID)
);

-- Get all active assets by department
SELECT Department, COUNT(*) AS TotalAssets
FROM Assets
WHERE Status = 'Active'
GROUP BY Department
ORDER BY TotalAssets DESC;

-- Assets with expired warranty
SELECT AssetName, SerialNumber, AssignedTo, WarrantyExpiry
FROM Assets
WHERE WarrantyExpiry < CURDATE()
ORDER BY WarrantyExpiry;

-- Full asset maintenance history
SELECT 
    a.AssetName,
    a.AssignedTo,
    m.MaintenanceDate,
    m.Description,
    m.TechnicianName
FROM Assets a
JOIN MaintenanceLogs m ON a.AssetID = m.AssetID
ORDER BY m.MaintenanceDate DESC;
