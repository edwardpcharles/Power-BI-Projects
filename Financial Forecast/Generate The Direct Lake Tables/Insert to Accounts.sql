-- Insert statements for Accounts table

-- Income Accounts
INSERT INTO Accounts (AccountID, AccountDesc, IncomeFlag, CogsFlag)
VALUES (1, 'New / Contracts / Projects', 'Y', 'N');

INSERT INTO Accounts (AccountID, AccountDesc, IncomeFlag, CogsFlag)
VALUES (2, 'WIP Revenue', 'Y', 'N');

INSERT INTO Accounts (AccountID, AccountDesc, IncomeFlag, CogsFlag)
VALUES (3, 'Change Orders', 'Y', 'N');

-- COGS (Cost of Goods Sold) Accounts
INSERT INTO Accounts (AccountID, AccountDesc, IncomeFlag, CogsFlag)
VALUES (4, 'Direct Material Costs', 'N', 'Y');

INSERT INTO Accounts (AccountID, AccountDesc, IncomeFlag, CogsFlag)
VALUES (5, 'Labor (construction workers)', 'N', 'Y');

INSERT INTO Accounts (AccountID, AccountDesc, IncomeFlag, CogsFlag)
VALUES (6, 'Subcontractor cost', 'N', 'Y');

INSERT INTO Accounts (AccountID, AccountDesc, IncomeFlag, CogsFlag)
VALUES (7, 'Equipment Rentals', 'N', 'Y');

INSERT INTO Accounts (AccountID, AccountDesc, IncomeFlag, CogsFlag)
VALUES (8, 'Project Overhead', 'N', 'Y');
