CREATE PROCEDURE [dbo].[usp_MiniDispo_Enprecis]
	 @LoadedDate VARCHAR(8) = NULL
AS
	
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

   SELECT 
S.Requirement,
AEBI.CaseID,
P.PartyID AS PartyID,
T.Title,
P.FirstName,
P.LastName,
CASE WHEN NS.PartyID IS NULL THEN 'False'
WHEN PNS.NonSolicitationID IS NOT NULL THEN 'Party' 
WHEN CNS.NonSolicitationID IS NOT NULL THEN 'Contact Mechanism' 
ELSE 'Other' END AS [People Non Solicitation Flag],

NS.Notes AS [People Notes], 
NST.NonSolicitationText AS [People Non-Solicitation Text]
FROM Event.AutomotiveEventBasedInterviews AEBI
	INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = AEBI.CaseID
	INNER JOIN Requirement.Requirements S ON SC.RequirementIDPartOf = S.RequirementID
    LEFT JOIN Party.People P ON AEBI.PartyID = P.PartyID
    LEFT JOIN Party.Titles T ON P.TitleID = T.TitleID
    LEFT JOIN dbo.NonSolicitations NS ON NS.PartyID = P.PartyID 
														AND ISNULL(NS.FromDate,'1 Jan 1900') < GETDATE()
                                                        AND ISNULL(NS.ThroughDate,'31 Dec 9999') > GETDATE() 
    LEFT JOIN Party.NonSolicitations PNS ON NS.NonSolicitationID = PNS.NonSolicitationID
    LEFT JOIN ContactMechanism.NonSolicitations CNS ON NS.NonSolicitationID = CNS.NonSolicitationID
    LEFT JOIN dbo.NonSolicitationTexts NST ON NS.NonSolicitationTextID = NST.NonSolicitationTextID

WHERE 

S.Requirement LIKE '%ENP%' + @LoadedDate + '%'

GROUP BY 
S.Requirement,
AEBI.CaseID,
P.PartyID,
T.Title,
P.FirstName,
P.LastName,
CASE WHEN NS.PartyID IS NULL THEN 'False'
WHEN PNS.NonSolicitationID IS NOT NULL THEN 'Party' 
WHEN CNS.NonSolicitationID IS NOT NULL THEN 'Contact Mechanism' 
ELSE 'Other' END,
NS.Notes, 
NST.NonSolicitationText