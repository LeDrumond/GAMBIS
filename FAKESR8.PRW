#INCLUDE "PROTHEUS.CH"

/*{Protheus.doc} FakeSR8

Esta função irá replicar um afastamento previamente cadastrado para um funcionário para os demais funcionários da base, de acordo com o filtro montado.
Não tem interface com usuário.
 
@author Leandro Drumond
*/
User Function FakeSR8()
Local aSR8Fields 	:= {}
Local aCampos 		:= {}
Local aAux			:= {}
Local cFilMat		:= "D MG 01 200000"		//Filial e matrícula do funcionário cujo afastamento será utilizado como modelo para replicar
Local cProcesso 	:= "00094"
Local cFilAux		:= "D MG 01"
Local cMatAux		:= "200000" 
Local nPula   		:= 13
Local nEspaco 		:= 13
Local nReg	  		:= 0
Local nX			:= 0
Local nY			:= 0
Local cAliasQry 	:= GetNextAlias()

DbSelectArea("SR8")
DbSetOrder(1)

aSR8Fields := dbStruct()

SR8->(DbSeek(cFilMat))
While SR8->(!Eof() .and. R8_FILIAL + R8_MAT == cFilMat )
	aAux := {}
	For nY := 1 to Len(aSR8Fields)
		If ValType(SR8->&(aSR8Fields[nY,1])) == "D"
			aAdd(aAux, SR8->&(aSR8Fields[nY,1]))
		ElseIf aSR8Fields[nY,2] == "M"
			Loop
		Else
			aAdd(aAux, SR8->&(aSR8Fields[nY,1]))
		EndIf
	Next nY
	aAdd(aCampos, aAux)
	SR8->(DbSkip())
EndDo

BeginSql alias cAliasQry
	SELECT RA_MAT
	FROM 	%table:SRA% SRA
	WHERE 	RA_PROCES = %exp:cProcesso% AND 
			RA_FILIAL = %exp:cFilAux% AND 
			RA_MAT <> %exp:cMatAux% AND
	ORDER BY RA_MAT				
EndSql

While (cAliasQry)->( !Eof() )
	For nX := 1 to Len(aCampos)
		RecLock("SR8",.T.)
		For nY := 1 to Len(aSR8Fields)
			If aSR8Fields[nY,2] == "M"
				Loop
			Else
				SR8->&(aSR8Fields[nY,1]) := aCampos[nX,nY]
			EndIf
		Next nY
		SR8->R8_MAT = (cAliasQry)->( RA_MAT )
		SR8->R8_PROCES = cProcesso
		SR8->(MsUnLock())
	Next nX
	(cAliasQry)->( DbSkip() )
EndDo

(cAliasQry)->( DbCloseArea() )

Return Nil
