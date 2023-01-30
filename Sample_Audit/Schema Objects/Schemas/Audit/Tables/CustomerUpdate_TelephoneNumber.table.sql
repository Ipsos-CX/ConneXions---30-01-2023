
CREATE TABLE [Audit].[CustomerUpdate_TelephoneNumber](
	[PartyID] [dbo].[PartyID] NOT NULL,
	[CaseID] [dbo].[CaseID] NOT NULL,
	[HomeTelephoneNumberContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[WorkTelephoneContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[MobileNumberContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[HomeTelephoneNumber] [dbo].[ContactNumber] NULL,
	[WorkTelephoneNumber] [dbo].[ContactNumber] NULL,
	[MobileNumber] [dbo].[ContactNumber] NULL,
	[AuditID] [dbo].[AuditID] NOT NULL,
	[AuditItemID] [dbo].[AuditItemID] NOT NULL,
	[CasePartyCombinationValid] [bit] NOT NULL,
	[ParentAuditItemID] [dbo].[AuditItemID] NULL,
	[DateProcessed] [datetime2](7) NOT NULL,
)