
--			 Views, Stored Procedures e Triggers

#1
CREATE VIEW vw_inscricoes AS
   SELECT P.id AS id_inscricao,
   	  P.codigo, 					
	  P.data AS data_inscricao,
	  P.cortesia,
	  P.presenca_confirmada,
	  P.inscricao_status_id AS status_id,
	  S.descricao AS status_descricao,
	  P.tipo_inscricao_id,
	  T.descricao AS tipo_inscricao_descricao,
	  P.participante_id,
	  PA.nome AS nome_participante,
	  PA.email,
	  PA.cpf,
	  PA.ativo,
	  PA.cidade,
	  PA.uf,
	  PA.sexo,
	  PA.telefone,
	  PA.data_cadastro AS data_cadastro_participante,
	  instituicao_representada
   FROM participante_inscricao P
      JOIN inscricao_status       S 
      JOIN tipo_inscricao         T
      JOIN evento                 E
      JOIN participante           PA
   WHERE S.id  = P.inscricao_status_id
       AND T.id  = P.tipo_inscricao_id
       AND PA.id = P.participante_id
       AND E.id  = T.evento_id;

#Chamar a View_vw_inscricoes
SELECT * FROM vw_inscricoes;


#2
CREATE VIEW vw_inscricoes_minicursos AS
	SELECT 	TI.id AS id_inscricao,
		E.nome AS nome_evento,
		P.nome AS nome_participante,
		P.email,   
		P.cpf,
		MI.data AS data_inscricao_minicurso,
		M.descricao AS nome_minicurso,
		I.nome AS nome_instrutor_minicurso,
		MI.presenca_confirmada 
	FROM evento                 E 
	   JOIN minicurso              M
	   JOIN minicurso_inscricao    MI
	   JOIN participante           P
	   JOIN participante           I
	   JOIN participante_inscricao PI
	   JOIN tipo_inscricao         TI
	WHERE PI.participante_id = P.id
	   AND TI.id              = PI.tipo_inscricao_id
	   AND E.id               = TI.evento_id
	   AND MI.participante_id = P.id
	   AND MI.minicurso_id    = M.id
	   AND M.instrutor_id     = I.id;

SELECT * FROM vw_inscricoes_minicursos;


#3
SELECT * FROM vw_minicursos_eventos;

CREATE OR REPLACE VIEW vw_minicursos_eventos AS  	/*CRIA OU SUBSTITUI A VISÃO*/
   SELECT M.id AS id_minicurso
          M.descricao AS nome_minicurso
          E.nome AS nome_evento
          M.data_cadastro
          M.total_vagas
          M.minicurso_tipo_id
          MT.descricao AS minicurso_tipo_descricao
          M.minicurso_turno_id turno_id
          MO.descricao AS turno_descricao  
          I.nome AS nome_instrutor
          I.email AS email_instrutor
          I.cpf AS cpf__instrutor 
   FROM minicurso M
      JOIN minicurso_inscricao MI
      JOIN minicurso_tipo MT
      JOIN minicurso_turno     MO 
      JOIN evento       E
      JOIN participante P			-- o vinculo com o  participante é para poder trazer o evento e o minicurso já que o minicurso não tem vinculo com o evento e vice -versa
      JOIN participante I
      JOIN participante_inscricao PI
      JOIN tipo_inscricao         TI
   WHERE P.id                 	= PI.participante_id
      AND MI.participante_id   	= P.id
      AND PI.tipo_inscricao_id 	= TI.id
      AND TI.evento_id         	= E.id
      AND MT.id 		= M.minicurso_tipo_id
      AND MO.id                	= M.minicurso_turno_id
      AND I.id                 	= M.instrutor_id;


#4a

#drop procedure sp_evento_participantes;

DELIMITER $$

CREATE PROCEDURE `dbeventos`.`sp_evento_participantes` (id_evento INT)
   	BEGIN
		SELECT  P.nome     nome_participante,
				   P.email      email_participante,
				   P.cpf        cpf_participante,	
				   E.nome       nome_evento
			  FROM evento 			      E
			  JOIN participante           P
			  JOIN participante_inscricao PI
			  JOIN tipo_inscricao         TI
			WHERE P.id                 =  PI.participante_id
			  AND PI.tipo_inscricao_id = TI.id
			  AND TI.evento_id         = E.id
			  AND E.id = id_evento;
	END $$;

CALL sp_evento_participantes (1);

/*
b. Uma procedure chamada sp_evento_participantes_total , que pode receber
opcionalmente o id de um evento como parâmetro, e deve retornar a lista de participantes inscritos
(deve retornar somente as colunas nome_evento, total_inscritos );
*/
CALL sp_evento_participantes_total(NULL);
-- DROP procedure sp_evento_participantes_total;

DELIMITER $$

CREATE PROCEDURE `dbeventos`.`sp_evento_participantes_total` (id_evento INT)
    
      
	BEGIN
     IF id_evento IS NOT NULL THEN
        
	   SELECT E.nome nome_evento 
			 ,COUNT(*) AS total_inscritos
		 FROM evento E
		 JOIN participante           P
		 JOIN participante_inscricao PI
		 JOIN tipo_inscricao         TI 
		WHERE P.id  = PI.participante_id
		  AND PI.tipo_inscricao_id  = TI.id
		  AND TI.evento_id = E.id
          AND (E.id = id_evento)
		GROUP BY 1;
	
	ELSE
		SELECT E.nome nome_evento 
			 ,COUNT(*)
		 FROM evento E
		 JOIN participante           P
		 JOIN participante_inscricao PI
		 JOIN tipo_inscricao         TI 
		WHERE P.id  = PI.participante_id
		  AND PI.tipo_inscricao_id  = TI.id
		  AND TI.evento_id = E.id
		GROUP BY 1;
    END IF;
   END $$
 
/*
c. Uma procedure chamada sp_minicursos_participantes , que pode receber opcionalmente o
id de um minicurso como parâmetro, e deve retornar a lista de participantes inscritos (deve retornar
somente as colunas nome_minicurso , nome_participante, email_participante, cpf_participante,
nome_evento );
*/

CALL sp_minicursos_participantes(NULL);
 -- DROP procedure sp_minicursos_participantes;

DELIMITER $$

CREATE PROCEDURE `dbeventos`.`sp_minicursos_participantes` (id_minicurso INT)
    
      
	BEGIN
     IF id_minicurso IS NOT NULL THEN
        
	   SELECT M.descricao      nome_minicurso
             ,P.nome           nome_participante
             ,P.email          email_participante
             ,P.cpf            cpf_participante
             ,E.nome 		   nome_evento	
         FROM minicurso    M
         JOIN participante P
         JOIN minicurso_inscricao MI
         JOIN participante_inscricao PI 
         JOIN tipo_inscricao TI
		 JOIN evento    E
		WHERE M.id = MI.minicurso_id
          AND MI.participante_id = P.id
          AND PI.participante_id = P.id
          AND PI.tipo_inscricao_id = TI.id
          AND TI.evento_id = E.id
          AND M.id = id_minicurso;
           
          
			
	
	ELSE
		SELECT M.descricao      nome_minicurso
             ,P.nome           nome_participante
             ,P.email          email_participante
             ,P.cpf            cpf_participante
             ,E.nome 		   nome_evento	
         FROM minicurso    M
         JOIN participante P
         JOIN minicurso_inscricao MI
         JOIN participante_inscricao PI 
         JOIN tipo_inscricao TI
		 JOIN evento    E
		WHERE M.id = MI.minicurso_id
          AND MI.participante_id = P.id
          AND PI.participante_id = P.id
          AND PI.tipo_inscricao_id = TI.id
          AND TI.evento_id = E.id;
    END IF;
   END $$
 
/*
5. (3,5 pontos) Utilizando triggers , crie scripts para:
a. Crie uma tabela (InnoDB) chamada log , com as seguintes colunas (todas de preenchimento
obrigatório):
id (INT), data_acao (DATETIME), tipo_acao (VARCHAR(50)), descricao_acao
(VARCHAR(500))
*/

CREATE TABLE LOG 
 (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
  data_acao  DATETIME NOT NULL,
  tipo_acao  VARCHAR(50) NOT NULL,
  descricao_acao VARCHAR(500) NOT NULL	
 ) ENGINE=INNODB;


 /*
b. Elabore um script para criação de uma trigger chamada tg_log_add_participante na tabela de
participantes que insira um registro na tabela de log para cada participante adicionado. Exemplo
(na tabela log):

id 	data_acao 		tipo_acao	descricao_acao		
1 	2017-05-10 17:47:23 	INSERT		Novo participante adicionado <nome do participante>.
*/    

DELIMITER $$

DROP TRIGGER IF EXISTS `dbeventos`.`tg_log_add_participante` $$
CREATE TRIGGER `dbeventos`.`tg_log_add_participante` AFTER INSERT ON participante
 FOR EACH ROW
BEGIN
   SET @descricao = CONCAT('Novo participante adicionado ', new.nome); 
   INSERT INTO LOG 

             (data_acao, tipo_acao, descricao_acao) 
      VALUES (NOW(), 'INSERT', @descricao);



END $$

DELIMITER ;



/*
c. Elabore um script para criação de uma trigger chamada tg_log_remove_participante na tabela
de participantes para registrar no log cada vez que um participante for removido:
*/


DELIMITER $$

DROP TRIGGER IF EXISTS `dbeventos`.`tg_log_remove_participante` $$
CREATE TRIGGER `dbeventos`.`tg_log_remove_participante` AFTER DELETE ON participante
 FOR EACH ROW
BEGIN
   SET @descricao = CONCAT('Participante removido ', old.nome); 
   INSERT INTO LOG 

             (data_acao, tipo_acao, descricao_acao) 
      VALUES (NOW(), 'DELETE', @descricao);



END $$

DELIMITER ;

/*
d. Elabore um script para criação de uma trigger chamada tg_log_update_evento na tabela de
evento para registrar no log cada vez que os dados do evento forem atualizados:
*/

DELIMITER $$

DROP TRIGGER IF EXISTS `dbeventos`.`tg_log_update_evento` $$
CREATE TRIGGER `dbeventos`.`tg_log_update_evento` AFTER UPDATE ON participante
 FOR EACH ROW
BEGIN
   SET @descricao = CONCAT('Evento ', old.nome,' atualizado'); 
   INSERT INTO LOG 

             (data_acao, tipo_acao, descricao_acao) 
      VALUES (NOW(), 'UPDATE', @descricao);



END $$

DELIMITER ;