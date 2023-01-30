CREATE PROCEDURE [SelectionOutput].[uspGetSelectionOutput_Postal]

AS

SELECT		PO.Password, PO.ID, FullModel, Model, PO.sType, PO.CarReg, PO.Title, PO.Initial, PO.Surname, PO.Fullname, PO.DearName, PO.CoName, PO.Add1, PO.Add2, PO.Add3, PO.Add4, PO.Add5, PO.Add6, PO.Add7, 
                      PO.Add8, PO.Add9, PO.CTRY, PO.EmailAddress, PO.Dealer, PO.sno, PO.ccode, PO.modelcode, PO.lang, PO.manuf, PO.gender, PO.qver, PO.blank, PO.etype, PO.reminder, PO.week, PO.test, PO.SampleFlag, 
                      PO.SalesServiceFile,PO.PartyID
FROM        SelectionOutput.Postal PO
LEFT JOIN	SelectionOutput.ReoutputCases R ON PO.ID = R.CaseID 

WHERE     (Outputted = 1) AND R.CaseID IS NULL
--BUG 14195 
ORDER BY row_number() OVER (PARTITION BY lang ORDER BY lang), lang