#INCLUDE "PROTHEUS.CH"

/*{Protheus.doc} FakeSRA

Cria funcionarios novos baseado em um modelo pr�-existente.
@author Leandro Drumond
*/
User Function FakeSRA()
Local aArea  	:= GetArea()
Local aSRAFields:= {}
Local cAliasQry := GetNextAlias()
Local nX		:= 0
Local nY		:= 0
Local nZ		:= 0
Local cFunc		:= "00"
Local lCriaSRD	:= .F.					//Se deve criar registros na SRD para os fakes
Local cAnoSRD	:= "2011"				//Ano para cria��o dos registros na SRD
Local aFakes	:= {10000, 10000, 10000, 10000}		//N�mero de funcion�rios que ser�o criados por filial
Local aFiliais	:= {"D MG 01 ", "D RJ 01 ", "M PR 01 ", "M SP 01 "}		//Filiais onde ser�o criados os fakes
Local cMatAux	:= "000001"				//Matr�cula a partir da qual ser�o gerados os fakes
Local cMatFake	:= "200000"				//Matr�cula inicial para os fakes
Local cIndice	:= "00001"				//C�digo inclu�do na frente do nome (RA_NOME)
Local cProcesso	:= "00103"				//Processo dos funcion�rios fakes

CursorWait()

DbSelectArea("SRA")
DbSetOrder(1)

aSRAFields 	:= dbStruct()

BeginSql alias cAliasQry
	SELECT *
	FROM 		%table:SRA% SRA
	WHERE RA_MAT = %exp:cMatAux%
	ORDER BY RA_MAT				
EndSql

For nX := 1 to Len(aFakes)
	cMatFake := "200000"
	For nZ := 1 to aFakes[nX]

		While .T.
			If SRA->(DbSeek(aFiliais[nX] + cMatFake)) //Se a matr�cula j� existir, soma 1 e continua buscado at� na� encontrar.
				cMatFake := Soma1(cMatFake)
			Else
				Exit
			EndIf
		EndDo
		
		Conout(".....Fake: " + AllTrim(STR(nZ)))
		RecLock("SRA",.T.)
		
		For nY := 1 to Len(aSRAFields)
			If ValType(SRA->&(aSRAFields[nY,1])) == "D"
				SRA->&(aSRAFields[nY,1]) := StoD((cAliasQry)->&(aSRAFields[nY,1]))
			ElseIf aSRAFields[nY,2] == "M"
				Loop
			Else
				SRA->&(aSRAFields[nY,1]) := (cAliasQry)->&(aSRAFields[nY,1])
			EndIf
		Next nY
		
		SRA->RA_MAT 	:= cMatFake
		SRA->RA_CIC 	:= GeraCPFVld()	//Gera um n�mero de CPF v�lido
		SRA->RA_PIS 	:= GeraPISVld()	//Gera um n�mero de PIS v�lido
		SRA->RA_NOME 	:= "TESTE PERFORMANCE - " + cIndice
		SRA->RA_CATFUNC := "M"
		SRA->RA_PROCES 	:= cProcesso
		SRA->RA_FILIAL 	:= aFiliais[nX]
		
		MsUnLock()
		
		If lCriaSRD
			CriaSRDFake((cAliasQry)->RA_FILIAL, (cAliasQry)->RA_MAT,cAnoSRD,cMatFake)
		EndIf
		
		cIndice := Soma1(cIndice)
		cMatFake := Soma1(cMatFake)	
	
	Next nZ

Next nX

(cAliasQry)->( DbCloseArea() )

CursorArrow()

RestArea(aArea)

Return Nil

/*{Protheus.doc} GeraCPFVld

Gera um CPF v�lido

@author Leandro Drumond
*/
Static Function GeraCPFVld()
Local aCpf1		:= Array(9,3)
Local aCpf2 	:= Array(10,3)
Local cCpf		:= ""
Local nX 		:= 0
Local nAux		:= 11
Local nTotAux	:= 0
Local nDig1 	:= 0
Local nDig2 	:= 0

For nX :=1 to 9
	aCpf1[nX,1] := Randomize(0,9) 
	aCpf1[nX,2] := nAux - nX
	aCpf1[nX,3] := aCpf1[nX,2] * aCpf1[nX,1]
	nTotAux += aCpf1[nX,3]   
Next nX

nDig1 := nTotAux % 11

If nDig1 < 2
	nDig1 := 0
Else
	nDig1 := 11 - nDig1
EndIf

nTotAux := 0

For nX := 1 to 9
	aCpf2[nX,1] := aCpf1[nX,1]
	aCpf2[nX,2] := aCpf1[nX,2]+1
	aCpf2[nX,3] := aCpf2[nX,2] * aCpf2[nX,1]
	nTotAux += aCpf2[nX,3] 
Next nX

aCpf2[10,1] := nDig1
aCpf2[10,2] := 2
aCpf2[10,3] := aCpf2[10,2] * aCpf2[10,1]
nTotAux += aCpf2[10,3]

nDig2 := nTotAux % 11

If nDig2 < 2
	nDig2 := 0
Else
	nDig2 := 11 - nDig2
EndIf

For nX := 1 to 9
	cCpf += AllTrim(Str(aCpf1[nX,1]))
Next nX

cCpf += AllTrim(Str(nDig1)) + AllTrim(Str(nDig2))

Return cCpf

/*{Protheus.doc} GeraPISVld

Gera um PIS v�lido

@author Leandro Drumond
*/
Static Function GeraPISVld()
Local aPIS		:= Array(10,2)
Local aPeso 	:= {3, 2, 9, 8, 7, 6, 5, 4, 3, 2}
Local nX 		:= 0
Local nTotAux	:= 0
Local nDig		:= 0
Local cPIS		:= ""

For nX :=1 to 10
	aPIS[nX,1] := Randomize(0,9) 
	aPIS[nX,2] := aPeso[nX] * aPIS[nX,1]
	nTotAux += aPIS[nX,2]   
Next nX

nDig := 11 - (nTotAux % 11)

nDig := If(nDig >= 10, 0, nDig)

For nX := 1 to 10
	cPIS += AllTrim(Str(aPIS[nX,1]))
Next nX

cPIS += AllTrim(Str(nDig))

Return cPIS

/*{Protheus.doc} CriaSRDFake

Duplica os registros da SRD do funcion�rio original para o fake

@author Leandro Drumond
*/

Static Function CriaSRDFake(cFilAux,cMatAux,cAnoSRD,cNewMat)
Local aArea 		:= GetArea()
Local aSRDFields	:= {}
Local cAliasSRD		:= GetNextAlias()
Local cDataIni		:= cAnoSrd + "01"		//Per�odo inicial para a gera��o dos registros
Local cDataFim		:= cAnoSrd + "13"		//Per�odo final para a gera��o dos registros
Local nX			:= 0

DbSelectArea("SRD")
DbSetOrder(1)

aSRDFields := DbStruct()

BeginSql alias cAliasSRD
	SELECT 		*
	FROM 		%table:SRD% SRD
	WHERE 	RD_FILIAL = %exp:cFilAux%  AND
			RD_MAT = %exp:cMatAux% AND
			RD_DATARQ >= %exp:cDataIni% AND
			RD_DATARQ <= %exp:cDataFim% AND
			SRD.%NotDel%
	ORDER BY RD_PD,RD_SEQ				
EndSql

While (cAliasSRD)->(!Eof())
	RecLock("SRD",.T.)
	For nX := 1 to Len(aSRDFields)
		If ValType(SRD->&(aSRDFields[nX,1])) == "D"
			SRD->&(aSRDFields[nX,1]) := StoD((cAliasSRD)->&(aSRDFields[nX,1]))
		Else
			SRD->&(aSRDFields[nX,1]) := (cAliasSRD)->&(aSRDFields[nX,1])
		EndIf
	Next nX
	SRD->RD_MAT := cNewMat
	MsUnLock()
	(cAliasSRD)->(DbSkip())
EndDo

(cAliasSRD)->(DbCloseArea())

RestArea(aArea)

Return Nil