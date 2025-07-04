import fabric.functions as fn
import logging

udf = fn.UserDataFunctions()


@udf.connection(argName="myWarehouse", alias="constructiondat")
@udf.function()
def create_edit(myWarehouse: fn.FabricSqlConnection, AccountID: int, FiscalPeriodID: int, DepartmentID: int, value: float) -> str:

    whSqlConnection = myWarehouse.connect()
    
    cursor = whSqlConnection.cursor()
    logging.info('I connected to the SQL Warehouse')
    query = """
        EXEC [construction_date].[dbo].[update_record]
        @AccountID = ?,           
        @FiscalPeriodID = ?,     
        @DepartmentID = ?,        
        @NewValue = ?;
    """
    data = (AccountID, FiscalPeriodID, DepartmentID, value)
    cursor.execute(query,data)
    cursor.close()
    whSqlConnection.commit()
    whSqlConnection.close()

    return 'Budget has been Saved'
