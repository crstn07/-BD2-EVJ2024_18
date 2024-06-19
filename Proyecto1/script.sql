


-- crear el procedimiento PR3
CREATE PROCEDURE PR3 
    @Email NVARCHAR(256), 
    @CodCourse INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId UNIQUEIDENTIFIER;
    DECLARE @TutorId UNIQUEIDENTIFIER;
    DECLARE @ProfileId INT;
    DECLARE @Credits INT;
    DECLARE @CreditsRequired INT;

    BEGIN TRANSACTION;

    -- Obtener el ID del usuario 
    SELECT @UserId = Id
    FROM proyecto1.Usuarios
    WHERE Email = @Email;

    -- Obtener el ProfileId del usuario
    SELECT @ProfileId = Id
    FROM proyecto1.ProfileStudent
    WHERE UserId = @UserId;

    -- Obtener los créditos actuales
    SELECT @Credits = Credits
    FROM proyecto1.ProfileStudent
    WHERE Id = @ProfileId;

    -- Obtener los créditos requeridos del curso
    SELECT @CreditsRequired = CreditsRequired
    FROM proyecto1.Course
    WHERE CodCourse = @CodCourse;

    -- Verificar si el usuario tiene suficientes créditos para el curso
    IF @Credits >= @CreditsRequired
    BEGIN
        -- Insertar en la tabla CourseAssignment
        INSERT INTO BD2.proyecto1.CourseAssignment (StudentId, CourseCodCourse)
        VALUES (@UserId, @CodCourse);

        -- Notificar al estudiante
        INSERT INTO BD2.proyecto1.Notification (UserId, Message, Date)
        VALUES (@UserId, 'Has sido asignado al curso', GETDATE());

        -- Obtener el TutorId para el curso
        SELECT @TutorId = TutorId 
        FROM BD2.proyecto1.CourseTutor 
        WHERE CourseCodCourse = @CodCourse;

        -- Notificar al tutor
        INSERT INTO BD2.proyecto1.Notification (UserId, Message, Date)
        VALUES (@TutorId, 'Un nuevo alumno ha sido asignado a tu curso', GETDATE());
    END
    ELSE
    BEGIN
        -- Notificar al estudiante que no tiene suficientes créditos
        INSERT INTO BD2.proyecto1.Notification (UserId, Message, Date)
        VALUES (@UserId, 'No cuentas con creditos suficientes para asignarte este curso', GETDATE());
    END

    COMMIT TRANSACTION;
END;
GO


-- crear el procedimiento PR2
CREATE PROCEDURE PR2 
    @Email NVARCHAR(256), 
    @CodCourse INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    DECLARE @UserId UNIQUEIDENTIFIER;
    DECLARE @RoleId UNIQUEIDENTIFIER;
    DECLARE @TutorCode NVARCHAR(50);  -- Ajusta el tamaño del tipo de datos según corresponda

    -- Obtener el ID del usuario y verificar que el email esté confirmado
    SELECT @UserId = Id
    FROM proyecto1.Usuarios
    WHERE Email = @Email AND EmailConfirmed = 1;

    IF @UserId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR ('El usuario no existe o no tiene una cuenta activa.', 16, 1);
        RETURN;
    END

    -- Obtener el RoleId para el rol de Tutor
    SELECT @RoleId = Id 
    FROM proyecto1.Roles 
    WHERE RoleName = 'Tutor';

    -- Asegurar que RoleId no es NULL
    IF @RoleId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR ('El rol de Tutor no existe.', 16, 1);
        RETURN;
    END

    -- Generar un código único para el tutor
    SET @TutorCode = NEWID();

    -- Añadir el rol de tutor al usuario
    INSERT INTO proyecto1.UsuarioRole (UserId, RoleId, IsLatestVersion)
    VALUES (@UserId, @RoleId, 1);  -- Aseguramos que IsLatestVersion tenga un valor predeterminado

    -- Crear el perfil de tutor
    INSERT INTO proyecto1.TutorProfile (UserId, TutorCode)
    VALUES (@UserId, @TutorCode);  -- Aseguramos que TutorCode no sea nulo

    -- Asignar el curso al tutor
    INSERT INTO proyecto1.CourseTutor (CourseCodCourse, TutorId)
    VALUES (@CodCourse, @UserId);

    -- Notificar al usuario
    INSERT INTO proyecto1.Notification (UserId, Message, Date)
    VALUES (@UserId, 'Has sido promovido al rol de tutor.', GETDATE());

    COMMIT TRANSACTION;
END;
GO

-- Crear la función dbo.F4
CREATE FUNCTION dbo.F4()
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM proyecto1.HistoryLog
);
GO

-- Crear la función dbo.F2
CREATE FUNCTION dbo.F2(@Id INT)
RETURNS TABLE
AS
RETURN	
(
    SELECT c.CodCourse, c.Name
    FROM proyecto1.Course c
    JOIN proyecto1.CourseTutor ct ON c.CodCourse = ct.CourseCodCourse
    JOIN proyecto1.TutorProfile tp ON ct.TutorId = tp.UserId
    WHERE tp.Id = @Id
);

-- >>>>>>>>>>>>>>>>TRIGGER PARA HISTORYLOG<<<<<<<<<<<<<<<<

-- TRIGGER COURSE
CREATE TRIGGER proyecto1.TriggerCourse
ON proyecto1.Course
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @Operacion VARCHAR(20);
    DECLARE @Descripcion VARCHAR(100);

   IF EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'DELETE';
    ELSE
        SET @Operacion = 'UPDATE';

    SET @Descripcion = 'Operacion ' + @Operacion + ' Exitosa - Tabla Course';

    INSERT INTO proyecto1.HistoryLog ([Date], Description)
    VALUES (GETDATE(), @Descripcion);
END;

-- TRIGGER COURSEASSIGNMENT
CREATE TRIGGER proyecto1.TriggerCourseAssignment
ON proyecto1.CourseAssignment
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @Operacion VARCHAR(20);
    DECLARE @Descripcion VARCHAR(100);

   IF EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'DELETE';
    ELSE
        SET @Operacion = 'UPDATE';

    SET @Descripcion = 'Operacion ' + @Operacion + ' Exitosa - Tabla CourseAssigment';

    INSERT INTO proyecto1.HistoryLog ([Date], Description)
    VALUES (GETDATE(), @Descripcion);
END;


-- TRIGGER Course Tutor
CREATE TRIGGER proyecto1.TriggerCourseTutor
ON proyecto1.CourseTutor
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @Operacion VARCHAR(20);
    DECLARE @Descripcion VARCHAR(100);

   IF EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'DELETE';
    ELSE
        SET @Operacion = 'UPDATE';

    SET @Descripcion = 'Operacion ' + @Operacion + ' Exitosa - Tabla CourseTutor';

    INSERT INTO proyecto1.HistoryLog ([Date], Description)
    VALUES (GETDATE(), @Descripcion);
END;

-- No trigger para tabla HistoryLog
-- No trigger para tabla Notification

-- TRIGGER Profile Student
CREATE TRIGGER proyecto1.TriggerProfileStudent
ON proyecto1.ProfileStudent
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @Operacion VARCHAR(20);
    DECLARE @Descripcion VARCHAR(100);

   IF EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'DELETE';
    ELSE
        SET @Operacion = 'UPDATE';

    SET @Descripcion = 'Operacion ' + @Operacion + ' Exitosa - Tabla ProfileStudent';

    INSERT INTO proyecto1.HistoryLog ([Date], Description)
    VALUES (GETDATE(), @Descripcion);
END;

-- No trigger para tabla roles

-- TRIGGER TFA
CREATE TRIGGER proyecto1.TriggerTFA
ON proyecto1.TFA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @Operacion VARCHAR(20);
    DECLARE @Descripcion VARCHAR(100);

   IF EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'DELETE';
    ELSE
        SET @Operacion = 'UPDATE';

    SET @Descripcion = 'Operacion ' + @Operacion + ' Exitosa - Tabla TFA';

    INSERT INTO proyecto1.HistoryLog ([Date], Description)
    VALUES (GETDATE(), @Descripcion);
END;

-- TRIGGER TutorProfile
CREATE TRIGGER proyecto1.TriggerTutorProfile
ON proyecto1.TutorProfile
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @Operacion VARCHAR(20);
    DECLARE @Descripcion VARCHAR(100);

   IF EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'DELETE';
    ELSE
        SET @Operacion = 'UPDATE';

    SET @Descripcion = 'Operacion ' + @Operacion + ' Exitosa - Tabla TutorProfile';

    INSERT INTO proyecto1.HistoryLog ([Date], Description)
    VALUES (GETDATE(), @Descripcion);
END;


-- TRIGGER UsuarioRole
CREATE TRIGGER proyecto1.TriggerUsuarioRole
ON proyecto1.UsuarioRole
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @Operacion VARCHAR(20);
    DECLARE @Descripcion VARCHAR(100);

   IF EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'DELETE';
    ELSE
        SET @Operacion = 'UPDATE';

    SET @Descripcion = 'Operacion ' + @Operacion + ' Exitosa - Tabla UsuarioRole';

    INSERT INTO proyecto1.HistoryLog ([Date], Description)
    VALUES (GETDATE(), @Descripcion);
END;

-- TRIGGER USUARIOS
CREATE TRIGGER proyecto1.TriggerUsuarios
ON proyecto1.Usuarios
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @Operacion VARCHAR(20);
    DECLARE @Descripcion VARCHAR(100);

   IF EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'DELETE';
    ELSE
        SET @Operacion = 'UPDATE';

    SET @Descripcion = 'Operacion ' + @Operacion + ' Exitosa - Tabla Usuarios';

    INSERT INTO proyecto1.HistoryLog ([Date], Description)
    VALUES (GETDATE(), @Descripcion);
END;