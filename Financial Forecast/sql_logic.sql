DECLARE @BudgetID INT=1;
Declare @AccountID INT =1;
Declare @FiscalPeriodID INT =1;
Declare @DepartmentID INT = 1;
Declare @NewValue Decimal(18,2) = 10.01;


Update fb 
SET IsCurrentValue = 'N'
from [construction_date].[dbo].[FactBudget] as fb
where fb.AccountID = @AccountID
and fb.FiscalPeriodID = @FiscalPeriodID
and fb.DepartmentID = @DepartmentID
and fb.[Value] <> @NewValue
and fb.IsCurrentValue = 'Y'
;

INSERT INTO [construction_date].[dbo].[FactBudget]
(BudgetID, AccountID, FiscalPeriodID, DepartmentID, [Value], IsCurrentValue)
Select
@BudgetID
, @AccountID
, @FiscalPeriodID
, @DepartmentID
, @NewValue
, 'Y'
Where not exists (
select 1 
from [construction_date].[dbo].[FactBudget]
where AccountID = @AccountID
and FiscalPeriodID = @FiscalPeriodID
and DepartmentID = @DepartmentID
and [Value] = @NewValue
and IsCurrentValue = 'Y'
)