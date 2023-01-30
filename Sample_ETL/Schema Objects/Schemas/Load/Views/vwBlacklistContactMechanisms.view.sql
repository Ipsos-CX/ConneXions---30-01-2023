CREATE VIEW Load.vwBlacklistContactMechanisms

AS

-- EMAIL ADDRESS
SELECT 
      V.AuditItemID,
      V.MatchedODSEMailAddressID ContactMechanismID,
      (SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID,
      S.BlacklistStringID
FROM dbo.VWT V
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON V.EmailAddress NOT LIKE S.BlacklistString
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes T ON S.BlacklistTypeID = T.BlacklistTypeID
WHERE S.Operator = 'NOT LIKE'
AND ISNULL(V.MatchedODSEMailAddressID, 0) > 0 
AND (Getdate() Between S.Fromdate And ISNULL(ThroughDate, '2099-01-01'))    -- BUG 15510 - set ISNULL to use '2099-01-01'
UNION

SELECT 
      V.AuditItemID,
      V.MatchedODSEMailAddressID ContactMechanismID,
      (SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID,
      S.BlacklistStringID
FROM dbo.VWT V
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON V.EmailAddress = S.BlacklistString
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes T ON S.BlacklistTypeID = T.BlacklistTypeID
WHERE S.Operator = '='
AND ISNULL(V.MatchedODSEMailAddressID, 0) > 0 
AND (Getdate() Between S.Fromdate And ISNULL(ThroughDate,'2099-01-01'))    -- BUG 15510 - set ISNULL to use '2099-01-01'

UNION

SELECT 
      V.AuditItemID,
      V.MatchedODSEMailAddressID ContactMechanismID,
      (SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID,
      S.BlacklistStringID
FROM dbo.VWT V
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON V.EmailAddress LIKE S.BlacklistString
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes T ON S.BlacklistTypeID = T.BlacklistTypeID
WHERE S.Operator = 'LIKE'AND ISNULL(V.MatchedODSEMailAddressID, 0) > 0 
AND (Getdate() Between S.Fromdate And ISNULL(ThroughDate,'2099-01-01'))    -- BUG 15510 - set ISNULL to use '2099-01-01'

UNION

-- PRIVATE EMAIL ADDRESS
SELECT 
      V.AuditItemID,
      V.MatchedODSPrivEMailAddressID ContactMechanismID,
      (SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID,
      S.BlacklistStringID
FROM dbo.VWT V
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON V.PrivEmailAddress NOT LIKE S.BlacklistString
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes T ON S.BlacklistTypeID = T.BlacklistTypeID
WHERE S.Operator = 'NOT LIKE'
AND ISNULL(V.MatchedODSPrivEMailAddressID, 0) > 0 
AND (Getdate() Between S.Fromdate And ISNULL(ThroughDate,'2099-01-01'))    -- BUG 15510 - set ISNULL to use '2099-01-01'

UNION 

SELECT 
      V.AuditItemID,
      V.MatchedODSPrivEMailAddressID ContactMechanismID,
      (SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID,
      S.BlacklistStringID
FROM dbo.VWT V
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON V.PrivEmailAddress = S.BlacklistString
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes T ON S.BlacklistTypeID = T.BlacklistTypeID
WHERE S.Operator = '='
AND ISNULL(V.MatchedODSPrivEMailAddressID, 0) > 0 
AND (Getdate() Between S.Fromdate And ISNULL(ThroughDate,'2099-01-01'))    -- BUG 15510 - set ISNULL to use '2099-01-01'

UNION

SELECT 
      V.AuditItemID,
      V.MatchedODSPrivEMailAddressID ContactMechanismID,
      (SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID,
      S.BlacklistStringID
FROM dbo.VWT V
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON V.PrivEmailAddress LIKE S.BlacklistString
INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes T ON S.BlacklistTypeID = T.BlacklistTypeID
WHERE S.Operator = 'LIKE'
AND ISNULL(V.MatchedODSPrivEMailAddressID, 0) > 0 
AND (Getdate() Between S.Fromdate And ISNULL(ThroughDate,'2099-01-01'))    -- BUG 15510 - set ISNULL to use '2099-01-01'







