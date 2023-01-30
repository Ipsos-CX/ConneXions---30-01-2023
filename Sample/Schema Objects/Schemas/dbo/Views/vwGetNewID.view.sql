CREATE VIEW dbo.vwGetNewID
AS

-- View created to allow SelectionOutput.udfGeneratePassword function 
-- to be able to use NewID (which is not allowed in functions).

SELECT NewId() AS [NewID]


