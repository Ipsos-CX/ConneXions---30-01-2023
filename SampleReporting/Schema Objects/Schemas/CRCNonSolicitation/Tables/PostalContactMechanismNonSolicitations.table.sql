CREATE TABLE [CRCNonSolicitation].[PostalContactMechanismNonSolicitations]
(
	PartyID dbo.PartyID NOT NULL, 
	NonSolicitationText NVARCHAR(50) NULL,
	ContactMechanismID dbo.ContactMechanismID NOT NULL
)
