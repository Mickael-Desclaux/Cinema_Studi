CREATE SCHEMA cinema;

DROP TABLE IF EXISTS cinema.user;
CREATE TABLE cinema.user
(
    ID        SERIAL PRIMARY KEY NOT NULL,
    Email     VARCHAR(255)       NOT NULL,
    Password  VARCHAR(255)       NOT NULL,
    Role_ID   INT                NOT NULL,
    Cinema_ID INT
);

DROP TABLE IF EXISTS cinema.role;
CREATE TABLE cinema.role
(
    ID   SERIAL PRIMARY KEY NOT NULL,
    Name VARCHAR(30)        NOT NULL
);

DROP TABLE IF EXISTS cinema.cinema CASCADE;
CREATE TABLE cinema.cinema
(
    ID       SERIAL PRIMARY KEY NOT NULL,
    Name     VARCHAR(50)        NOT NULL,
    "Adress" VARCHAR(255)
);

DROP TABLE IF EXISTS cinema.room CASCADE;
CREATE TABLE cinema.room
(
    ID         SERIAL PRIMARY KEY NOT NULL,
    Cinema_ID  INT                NOT NULL,
    Max_Places INT                NOT NULL
);

DROP TABLE IF EXISTS cinema.movie CASCADE;
CREATE TABLE cinema.movie
(
    ID          SERIAL PRIMARY KEY NOT NULL,
    Name        VARCHAR(255)       NOT NULL,
    Length      INT                NOT NULL,
    Genre_ID    INT                NOT NULL,
    Description VARCHAR(1000)
);

DROP TABLE IF EXISTS cinema.movie_genre;
CREATE TABLE cinema.movie_genre
(
    ID   SERIAL PRIMARY KEY NOT NULL,
    Name VARCHAR(50)        NOT NULL
);

DROP TABLE IF EXISTS cinema.ticket;
CREATE TABLE cinema.ticket
(
    ID          SERIAL PRIMARY KEY NOT NULL,
    Session_ID  INT                NOT NULL,
    Category_ID INT                NOT NULL
);

DROP TABLE IF EXISTS cinema.ticket_Category CASCADE;
CREATE TABLE cinema.ticket_Category
(
    ID    SERIAL PRIMARY KEY NOT NULL,
    Name  VARCHAR(30)        NOT NULL,
    Price DECIMAL
);

DROP TABLE IF EXISTS cinema.session;
CREATE TABLE cinema.session
(
    ID        SERIAL PRIMARY KEY NOT NULL,
    Room_ID   INT                NOT NULL,
    Movie_ID  INT                NOT NULL,
    Screening TIMESTAMP          NOT NULL
);

ALTER TABLE cinema.user
    ADD CONSTRAINT FK_role
        FOREIGN KEY (Role_ID) REFERENCES cinema.user (ID);

ALTER TABLE cinema.user
    ADD CONSTRAINT FK_cinema
        Foreign KEY (Cinema_ID) REFERENCES cinema.cinema (ID);

ALTER TABLE cinema.room
    ADD CONSTRAINT FK_cinema
        FOREIGN KEY (cinema_id) REFERENCES cinema.cinema (ID);

ALTER TABLE cinema.movie
    ADD CONSTRAINT FK_genre
        FOREIGN KEY (genre_id) REFERENCES cinema.movie_genre (ID);

ALTER TABLE cinema.session
    ADD CONSTRAINT FK_room
        FOREIGN KEY (room_id) REFERENCES cinema.room (ID);

ALTER TABLE cinema.session
    ADD CONSTRAINT FK_movie
        FOREIGN KEY (movie_id) REFERENCES cinema.movie (ID);

ALTER TABLE cinema.ticket
    ADD CONSTRAINT FK_session
        FOREIGN KEY (session_id) REFERENCES cinema.session (ID);

ALTER TABLE cinema.ticket
    ADD CONSTRAINT FK_category
        FOREIGN KEY (category_id) REFERENCES cinema.ticket_Category (id);

INSERT INTO cinema.cinema (name, "Adress")
VALUES ('Cinema Bordeaux', '13 rue des combatants'),
       ('Cinema Pessac', '12 rue verte'),
       ('Cinema Biganos', '5 allée Maurice Lafon');

INSERT INTO cinema.role (Name)
VALUES ('ROLE_USER'),
       ('ROLE_ADMIN');

INSERT INTO cinema.user (Email, Password, Role_ID, Cinema_ID)
VALUES ('mdes@gmail.com', '1234', 1, 1),
       ('desm@gmail.com', '2468', 1, 2);

INSERT INTO cinema.user (email, password, role_id)
VALUES ('admin@gmail.com', '5678', 2);

INSERT INTO cinema.room (cinema_id, max_places)
VALUES (1, 400),
       (1, 400),
       (1, 400),
       (1, 400),
       (1, 400),
       (1, 400),
       (2, 300),
       (2, 300),
       (2, 300),
       (3, 150),
       (3, 150);

INSERT INTO cinema.movie_genre (Name)
VALUES ('Action'),
       ('Aventure'),
       ('Comédie'),
       ('Drame'),
       ('Comédie musicale'),
       ('Animation'),
       ('Horreur'),
       ('Science-Fiction'),
       ('Thriller');

INSERT INTO cinema.ticket_Category (name, price)
VALUES ('Plein tarif', 9.20),
       ('Étudiant', 7.60),
       ('Moins de 14 ans', 5.90);

INSERT INTO cinema.movie (name, length, genre_id, description)
VALUES ('Interstellar', 169, 8,
        'Le film raconte les aventures d’un groupe d’explorateurs qui utilisent une faille récemment ' ||
        'découverte dans l’espace-temps afin de repousser les limites humaines et partir à la conquête ' ||
        'des distances astronomiques dans un voyage interstellaire. '),

       ('Babylon', 189, 4, 'Los Angeles des années 1920. Récit d’une ambition démesurée et d’excès les plus fous, ' ||
                           'BABYLON retrace l’ascension et la chute de différents personnages lors de la création d’Hollywood,' ||
                           'une ère de décadence et de dépravation sans limites.'),

       ('Le menu', 168, 9,
        'Un couple se rend sur une île isolée pour dîner dans un des restaurants les plus en vogue du ' ||
        'moment, en compagnie d’autres invités triés sur le volet. Le savoureux menu concocté par le chef ' ||
        'va leur réserver des surprises aussi étonnantes que radicales...');

INSERT INTO cinema.session (room_id, movie_id, screening)
VALUES (1, 1, '2023-08-03 21:00');

CREATE OR REPLACE FUNCTION cinema.buy_ticket(p_session_id INT, p_category_id INT, p_quantity INT)
    RETURNS VOID AS
$$
DECLARE
    v_max_places   INT;
    v_sold_tickets INT;
BEGIN
    -- Get the maximum places of the room
    SELECT r.Max_Places
    INTO v_max_places
    FROM cinema.room r
             JOIN cinema.session s ON r.ID = s.Room_ID
    WHERE s.ID = p_session_id;

    -- Get the number of sold tickets for this session
    SELECT COUNT(*)
    INTO v_sold_tickets
    FROM cinema.ticket
    WHERE Session_ID = p_session_id;

    -- Check if there is enough available places in the room
    IF v_sold_tickets + p_quantity <= v_max_places THEN
        FOR i IN 1..p_quantity
            LOOP
                INSERT INTO cinema.ticket (Session_ID, Category_ID)
                VALUES (p_session_id, p_category_id);
            END LOOP;
    ELSE
        RAISE EXCEPTION 'Désolé, la session est complète.';
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT cinema.buy_ticket(1, 1, 2);

-- Check if the function buy_ticket() works if the room is complete
-- SELECT cinema.buy_ticket(1, 2, 399);

CREATE OR REPLACE FUNCTION cinema.add_movie(
    p_name VARCHAR(255),
    p_length INT,
    p_genre_id INT,
    p_desciption VARCHAR(1000)
)
    RETURNS VOID AS
$$
BEGIN
    INSERT INTO cinema.movie (name, length, genre_id, description)
    VALUES (p_name, p_length, p_genre_id, p_desciption);
END;
$$ LANGUAGE plpgsql;

SELECT cinema.add_movie('The Grand Budapest Hotel', 100, 3, 'Le film retrace les ' ||
                                                            'aventures de Gustave H, l’homme aux clés d’or d’un célèbre ' ||
                                                            'hôtel européen de l’entre-deux-guerres et du garçon d’étage ' ||
                                                            'Zéro Moustafa, son allié le plus fidèle.');

CREATE OR REPLACE FUNCTION cinema.add_session(
    p_cinema_id INT,
    p_room_id INT,
    p_movie_id INT,
    p_screening TIMESTAMP
)
    RETURNS VOID AS
$$
DECLARE
    v_user_id INT;
    v_admin   BOOLEAN;
BEGIN
    -- Get the current user's ID
    SELECT ID INTO v_user_id FROM cinema.user WHERE Email = CURRENT_USER;

    -- Check if the current user is an admin
    SELECT COUNT(*) > 0 INTO v_admin FROM cinema.user WHERE ID = v_user_id AND Role_ID = 2;

    -- Check if the user is the owner of the cinema or if the user is an admin
    IF v_admin OR (SELECT Cinema_ID FROM cinema.user WHERE ID = v_user_id) = p_cinema_id THEN
        INSERT INTO cinema.session (room_id, movie_id, screening)
        VALUES (p_room_id, p_movie_id, p_screening);
    ELSE
        RAISE EXCEPTION 'Accès interdit';
    END IF;
END;
$$ LANGUAGE plpgsql;
