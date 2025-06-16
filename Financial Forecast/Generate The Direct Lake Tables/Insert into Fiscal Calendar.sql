-- Insert statements for FiscalCalendar table

-- Starting FiscalPeriodID. Adjust if you have existing data.
DECLARE @startFiscalPeriodID INT = 1;

-- Loop for Fiscal Year 2024 to 2027
DECLARE @currentYear INT = 2024;
DECLARE @endYear INT = 2027;

WHILE @currentYear <= @endYear
BEGIN
    DECLARE @month INT = 1;
    WHILE @month <= 12
    BEGIN
        DECLARE @fiscalQuarter INT;
        SET @fiscalQuarter = CEILING(CAST(@month AS DECIMAL) / 3);

        INSERT INTO FiscalCalendar (
            FiscalPeriodID,
            EnglishFiscalPeriod,
            FiscalYear,
            FiscalYearPeriod,
            FiscalQuarter,
            FiscalYearQuarter
        )
        VALUES (
            @startFiscalPeriodID,
            'FY' + CAST(@currentYear AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(@month AS VARCHAR(2)), 2),
            @currentYear,
            CAST(@currentYear AS VARCHAR(4)) + RIGHT('0' + CAST(@month AS VARCHAR(2)), 2),
            @fiscalQuarter,
            CAST(@currentYear AS VARCHAR(4)) + 'Q' + CAST(@fiscalQuarter AS VARCHAR(1))
        );

        SET @startFiscalPeriodID = @startFiscalPeriodID + 1;
        SET @month = @month + 1;
    END;
    SET @currentYear = @currentYear + 1;
END;
