-- ============================================
-- IT Helpdesk Ticketing System
-- Author: Vikrant Verma
-- Description: Manage IT support tickets,
-- SLA tracking, and team performance
-- ============================================

CREATE TABLE Tickets (
    TicketID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(200),
    Description TEXT,
    Priority VARCHAR(20),
    Status VARCHAR(20) DEFAULT 'Open',
    AssignedTo VARCHAR(100),
    CreatedBy VARCHAR(100),
    CreatedAt DATETIME DEFAULT NOW(),
    ResolvedAt DATETIME,
    SLADeadline DATETIME
);

-- Open tickets by priority
SELECT Priority, COUNT(*) AS Total
FROM Tickets
WHERE Status = 'Open'
GROUP BY Priority
ORDER BY FIELD(Priority,'Critical','High','Medium','Low');

-- SLA breached tickets
SELECT TicketID, Title, AssignedTo, SLADeadline
FROM Tickets
WHERE Status != 'Closed'
AND SLADeadline < NOW();

-- Engineer performance report
SELECT AssignedTo,
    COUNT(*) AS TotalResolved,
    AVG(TIMESTAMPDIFF(HOUR, CreatedAt, ResolvedAt)) AS AvgResolutionHours
FROM Tickets
WHERE Status = 'Closed'
GROUP BY AssignedTo
ORDER BY TotalResolved DESC;
