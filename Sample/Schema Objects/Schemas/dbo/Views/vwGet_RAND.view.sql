CREATE VIEW dbo.vwGet_RAND
/*

Version	Created		Author		Purpose						Called by
1.0		20-Feb-2015	P.Doyle		View used by->    			SelectionOutput.udfGeneratePassword
                                								
*/


AS
    SELECT  RAND() AS MyRAND 
GO