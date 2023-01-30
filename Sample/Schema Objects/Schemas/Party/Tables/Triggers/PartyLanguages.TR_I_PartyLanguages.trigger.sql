CREATE TRIGGER Party.[TR_I_PartyLanguages] ON [Party].[PartyLanguages]
AFTER INSERT 
AS 
BEGIN
	UPDATE PL
	SET PL.PreferredFlag = 0
	FROM Party.PartyLanguages PL
	INNER JOIN INSERTED I ON PL.PartyID = I.PartyID
	AND PL.LanguageID <> I.LanguageID
END
