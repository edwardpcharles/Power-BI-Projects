CREATE PROC [dbo].[update_record] @AccountID INT,
@FiscalPeriodID INT,
@DepartmentID INT,
@NewValue DECIMAL (18 , 2)
AS BEGIN
    DECLARE
        @BudgetID INT;

    SELECT
        @BudgetID = min (BudgetID)
    FROM [construction_date].[dbo].[FactBudget] WHERE
        AccountID = @AccountID
        AND FiscalPeriodID = @FiscalPeriodID
        AND
            DepartmentID = @DepartmentID

    IF @BudgetID IS NULL BEGIN
        SELECT
            @BudgetID = ISNull (MAX (BudgetID) , 0) + 1
        FROM [construction_date].[dbo].[FactBudget];
    END

    UPDATE fb SET
        IsCurrentValue = 'N'
    FROM
        [construction_date].[dbo].[FactBudget] AS fb
    WHERE
        fb.AccountID = @AccountID
        AND fb.FiscalPeriodID = @FiscalPeriodID
        AND fb.DepartmentID = @DepartmentID
        AND fb.[Value] < > @NewValue
        AND
            fb.IsCurrentValue = 'Y';

    INSERT INTO [construction_date].[dbo].[FactBudget] (
        BudgetID,
        AccountID,
        FiscalPeriodID,
        DepartmentID,
        [Value],
        IsCurrentValue
    )
    SELECT
        @BudgetID,
        @AccountID,
        @FiscalPeriodID,
        @DepartmentID,
        @NewValue,
        'Y'
    WHERE
        NOT EXISTS (
            SELECT 1 FROM [construction_date].[dbo].[FactBudget] WHERE AccountID = @AccountID
            AND FiscalPeriodID = @FiscalPeriodID
            AND DepartmentID = @DepartmentID
            AND [Value] = @NewValue
            AND
                IsCurrentValue = 'Y'
        )
END
