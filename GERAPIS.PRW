#INCLUDE "PROTHEUS.CH"
/*{Protheus.doc} GeraPISVld

Gera um PIS válido

@author Leandro Drumond
*/

User Function GeraPISVld()
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