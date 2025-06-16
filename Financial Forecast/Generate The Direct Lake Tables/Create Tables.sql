-- Create Department Table
CREATE TABLE Department (
    DepartmentID INT,
    DepartmentName VARCHAR(255), -- Changed from NVARCHAR(255) to VARCHAR(255)
    ProjectManagerName VARCHAR(255) -- Changed from NVARCHAR(255) to VARCHAR(255)
);
GO

-- Create FiscalCalendar Table
CREATE TABLE FiscalCalendar (
    FiscalPeriodID INT,
    EnglishFiscalPeriod VARCHAR(50), -- Changed from NVARCHAR(50) to VARCHAR(50)
    FiscalYear INT,
    FiscalYearPeriod VARCHAR(50), -- Changed from NVARCHAR(50) to VARCHAR(50)
    FiscalQuarter INT,
    FiscalYearQuarter VARCHAR(50) -- Changed from NVARCHAR(50) to VARCHAR(50)
);
GO

-- Create Accounts Table
CREATE TABLE Accounts (
    AccountID INT,
    AccountDesc VARCHAR(255), -- Changed from NVARCHAR(255) to VARCHAR(255)
    IncomeFlag VARCHAR(1),
    CogsFlag VARCHAR(1)
);
GO

-- Create FactBudget Table
CREATE TABLE FactBudget (
    BudgetID INT,
    AccountID INT,
    FiscalPeriodID INT,
    DepartmentID INT,
    Value DECIMAL(18, 2),
    IsCurrentValue VARCHAR(1)
    -- Removed Foreign Key Constraints for now, as they often rely on declared PRIMARY KEYs.
    -- If Fabric supports REFERENCES without explicit PRIMARY KEY, they can be re-added.
    -- Otherwise, referential integrity is typically handled during data loading/ETL in data warehouses.
);
GO