/* 
	CS4504 - Formal Verification
	Dr Vasileios Koutavas
	Group Assignment 3 - Verification of String methods
	Stefano Lupo:		14334933 - 6 hours 
		About 4/5 hours were spent trying to get isSubstring to verify
		The problem was that isPrefix doesn't imply isSubstring
		However once that was figured out, the rest of the assignment only took about an hour or so
	Rowan Sutton:		13330793 - 5 Hours
		About 4 hours working on isSubstring as above
		1 Hour working on verifying the rest of the methods
	Average Hours: 5.5
*/



/*****************************************************************************
* isPrefix
* Determines whether or not pre is a prefix of string
*****************************************************************************/
predicate isPrefixPred(pre:string, str:string) {
	(|pre| <= |str|) && pre == str[..|pre|]
}

predicate isNotPrefixPred(pre:string, str:string) {
	(|pre| > |str|) || pre != str[..|pre|]
}

lemma PrefixNegationLemma(pre:string, str:string)
	ensures  isPrefixPred(pre,str) <==> !isNotPrefixPred(pre,str)
	ensures !isPrefixPred(pre,str) <==>  isNotPrefixPred(pre,str)
{}

method isPrefix(pre: string, str: string) returns (res:bool)
	ensures !res <==> isNotPrefixPred(pre,str)
	ensures  res <==> isPrefixPred(pre,str)
{
	if (|pre| > |str|) {
		return false;
	}

	return str[..|pre|] == pre;
}






/*****************************************************************************
* isSubstring
* determines whether or not sub is a substring of str
*****************************************************************************/
predicate isSubstringPred(sub:string, str:string) {
	exists i :: 0 <= i <= |str| &&  isPrefixPred(sub, str[i..])
}

predicate isNotSubstringPred(sub:string, str:string) {
	forall i :: 0 <= i <= |str| ==> isNotPrefixPred(sub,str[i..])
}

lemma SubstringNegationLemma(sub:string, str:string)
	ensures  isSubstringPred(sub,str) <==> !isNotSubstringPred(sub,str)
	ensures !isSubstringPred(sub,str) <==>  isNotSubstringPred(sub,str)
{}

method isSubstring(sub: string, str: string) returns (res:bool)
	// Dont even require invariants
	ensures  res ==> isSubstringPred(sub, str)
	ensures isNotSubstringPred(sub, str) ==> !res

	// Require invariants
	ensures isSubstringPred(sub, str) ==> res
	ensures !res ==> isNotSubstringPred(sub, str)
{

	// Short circuit exit
	if !(|sub| <= |str|) {
		return false;
	}

	var i := 0;
	res := false;

	while (i <= |str| - |sub|)
	invariant res ==> isSubstringPred(sub, str)
	invariant i <= |str| - |sub| + 1
	invariant forall x :: 0 <= x < i ==> isNotPrefixPred(sub, str[x..])
	{
		var tail := str[i..];
		var isAPrefix := isPrefix(sub, tail);
		if (isAPrefix) {
			assert isPrefixPred(sub, tail);
			assert isSubstringPred(sub, str);
			return true;
		} else {
			assert isNotPrefixPred(sub, tail);
			assert isNotSubstringPred(sub, tail[..|sub|]);
			i := i + 1;
		}
	}
}







/*****************************************************************************
* haveCommonKSubstring
* Checks whether two strings have a common substring of size k
*****************************************************************************/
predicate haveCommonKSubstringPred(k:nat, str1:string, str2:string) {
	exists i1, j1 :: 0 <= i1 <= |str1|- k && j1 == i1 + k && isSubstringPred(str1[i1..j1],str2)
}

predicate haveNotCommonKSubstringPred(k:nat, str1:string, str2:string) {
	forall i1, j1 :: 0 <= i1 <= |str1|- k && j1 == i1 + k ==>  isNotSubstringPred(str1[i1..j1],str2)
}

lemma commonKSubstringLemma(k:nat, str1:string, str2:string)
	ensures  haveCommonKSubstringPred(k,str1,str2) <==> !haveNotCommonKSubstringPred(k,str1,str2)
	ensures !haveCommonKSubstringPred(k,str1,str2) <==>  haveNotCommonKSubstringPred(k,str1,str2)
{}

method haveCommonKSubstring(k: nat, str1: string, str2: string) returns (found: bool)
	 // Trivial
	ensures found ==> haveCommonKSubstringPred(k,str1,str2)
	ensures haveNotCommonKSubstringPred(k,str1,str2) ==> !found

	// Not Trivial
	ensures haveCommonKSubstringPred(k,str1,str2) ==> found
	ensures !found ==> haveNotCommonKSubstringPred(k,str1,str2)
{
	// If either strings are smaller than k, they have no common substring of size k
	if (|str1| < k || |str2| < k) {
		assert haveNotCommonKSubstringPred(k, str1, str2);
		return false;
	}

	// All strings have common substring of length zero
	if (k == 0) {
		assert isPrefixPred(str1[0..0], str2[0..]);
		assert haveCommonKSubstringPred(k, str1, str2);
		return true;
	}

	var startIndex := 0;
	found := false;

	// Create each substring of size k from str1
	while (startIndex <= |str1| - k) 
	
	// startIndex always within bounds of str1
	// This requires + 1 as i is incremented once we reach fo the end of the string
	invariant startIndex + k <= |str1| + 1 

	// Invariant that proves we make progress towards the postcondition at each iteration
	// At each iteration, we know that all the substrings of str1 of length k starting from BEFORE
	// startIndex are not substrings of str2
	invariant forall si, ei :: 0 <= si < startIndex && ei == si + k ==> isNotSubstringPred(str1[si..ei], str2)	
	
	{
		var endIndex := startIndex + k;
		assert endIndex <= |str1|;

		// Get a substring of length k from str1							
		var substr := str1[startIndex..endIndex];
		assert |substr| == k;

		var isSubstr := isSubstring(substr, str2);
		if (isSubstr) {
			return true;
		}

		startIndex := startIndex + 1;
	}

	return false;
}





/*****************************************************************************
* maxCommonSubstringLength
* Finds the largest common substring between two strings
* Assume: all strings have a common substring of length zero
*****************************************************************************/
method maxCommonSubstringLength(str1: string, str2: string) returns (len:nat)
	requires (|str1| <= |str2|)
	ensures (forall k :: len < k <= |str1| ==> !haveCommonKSubstringPred(k,str1,str2))
	ensures haveCommonKSubstringPred(len,str1,str2)
{
	len := |str1|;
	while (len > 0) 
	// Invariant which shows we make progress towards post condition at each iteration
	invariant forall x :: len < x <= |str1| ==> !haveCommonKSubstringPred(x, str1, str2)
	{
		var hasCommonSubstrOfLen := haveCommonKSubstring(len, str1, str2);
		if (hasCommonSubstrOfLen) {
			return len;
		}
		len := len - 1;
	}
	
	// Help Dafny choose an existential
	assert isPrefixPred(str1[0..0], str2[0..]);
	return len;
}
