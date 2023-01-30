CREATE TABLE [SampleReport].[SummaryResponses]
(
	[Brand]				[varchar](200)	NULL,
	[Market]			[nvarchar](250)	NULL,
	[Questionnaire]		[varchar](200)	NULL,
	[EventsLoaded]		[int]			NULL,
	[TotalResponses]	[int]			NULL,
	[InvitesSent]		[int]			NULL,
	[EmailInvites]		[int]			NULL,
	[SMSInvites]		[int]			NULL,
	[PostalInvites]		[int]			NULL,
	[PhoneInvites]		[int]			NULL,
	[StartDate]			[datetime]		NULL,
	[EndDate]			[datetime]		NULL,
	[GeneratedDate]		[datetime]		NULL
) ON [PRIMARY]
