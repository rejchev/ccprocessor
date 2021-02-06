/**************************************************************************
 *                             UTF-8 string                               *
 *                     Автор: Феникс(komashchenko)                        *
 *                            Version: 1.1                                *
 *                  http://zizt.ru/  http://hlmod.ru/                     *
 * 03.05.2015 - V1.0: Релиз                                               *
 * 02.06.2015 - V1.1: Исправлены баги                                     *
 **************************************************************************/


#include <string>

/**
 * Returns whether two strings are equal.
 *
 * @param str1			First string (left).
 * @param str2			Second string (right).
 * @param caseSensitive	If true (default), comparison is case sensitive.
 * 						If false, comparison is case insensitive.
 * @return				True if equal, false otherwise.
 */
stock bool:UTF8StrEqual(const String:str1[], const String:str2[], bool:caseSensitive=true)
{
	return (UTF8strcmp(str1, str2, caseSensitive) == 0);
}

/**
 * Compares two strings parts lexographically.
 *
 * @param str1			First string (left).
 * @param str2			Second string (right).
 * @param num			Number of characters to compare.
 * @param caseSensitive	If true (default), comparison is case sensitive.
 *						If false, comparison is case insensitive.
 * @return				-1 if str1 < str2
 *						0 if str1 == str2
 *						1 if str1 > str2
 */
stock UTF8strncmp(const String:str1[], const String:str2[], num, bool:caseSensitive=true)
{
	if(!caseSensitive)
	{
		new a = strlen(str1)+190, b = strlen(str2)+190;
		decl String:aa[a], String:bb[b];
		strcopy(aa, a, str1);
		strcopy(bb, b, str2);
		UTF8CharToLower(aa);
		UTF8CharToLower(bb);
		return strncmp(aa, bb, num, true);
	}
	return strncmp(str1, str2, num, true);
}

/**
 * Compares two strings lexographically.
 *
 * @param str1			First string (left).
 * @param str2			Second string (right).
 * @param caseSensitive	If true (default), comparison is case sensitive.
 *						If false, comparison is case insensitive.
 * @return				-1 if str1 < str2
 *						0 if str1 == str2
 *						1 if str1 > str2
 */
stock UTF8strcmp(const String:str1[], const String:str2[], bool:caseSensitive=true)
{
	if(!caseSensitive)
	{
		new a = strlen(str1)+190, b = strlen(str2)+190;
		decl String:aa[a], String:bb[b];
		strcopy(aa, a, str1);
		strcopy(bb, b, str2);
		UTF8CharToLower(aa);
		UTF8CharToLower(bb);
		return strcmp(aa, bb, true);
	}
	return strcmp(str1, str2, true);
}

/**
 * Tests whether a string is found inside another string.
 *
 * @param str			String to search in.
 * @param substr		Substring to find inside the original string.
 * @param caseSensitive	If true (default), search is case sensitive.
 *						If false, search is case insensitive.
 * @return				-1 on failure (no match found). Any other value
 *						indicates a position in the string where the match starts.
 */
stock UTF8StrContains(const String:str[], const String:substr[], bool:caseSensitive=true)
{
	if(!caseSensitive)
	{
		new a = strlen(str)+190, b = strlen(substr)+190;
		decl String:aa[a], String:bb[b];
		strcopy(aa, a, str);
		strcopy(bb, b, substr);
		UTF8CharToLower(aa);
		UTF8CharToLower(bb);
		return StrContains(aa, bb, true);
	}
	return StrContains(str, substr, true);
}

/**
 * Делает с нижнего регистра верхний.
 *
 * @param string			строка для конвертации.
 * @return		количество символов которые были переведены в верхний регистр	
 */
stock UTF8CharToUpper(String:string[])
{
	new I = 0, O = strlen(string), Byte, K;
	while(I < O)
	{
		Byte = string[I];
		if(Byte >= 128)
		{
			if(Byte >= 240)
			{
				if(strlen(string[I]) < 4) break; 
				else I += 4; 
			}
			else if(Byte >= 224)
			{
				if(strlen(string[I]) < 3) break; 
				else I += 3; 
			}
			else if(Byte >= 192)
			{
				if(strlen(string[I]) < 2) break;
				Byte = (Byte % 32) * 64; 
				Byte += (string[I+1] % 64);
				if(1072 <= Byte <= 1103 || Byte == 1105 || 1110 <= Byte <= 1111 || Byte == 1169)
				{
					if(1105 <= Byte <= 1111) Byte = Byte-80;
					else if(Byte != 1169) Byte = Byte-32;
					else Byte--;
					string[I]   = 192 + RoundToFloor(float(Byte / 64));
					string[I+1] = 128 + (Byte % 64);
					K++;
				}
				I += 2;
			}
			else break;
		}
		else
		{
			if(97 <= Byte <= 122)
			{
				string[I] = Byte-32;
				K++;
			}
			I += 1;
		}
	}
	return K;
}

/**
 * Делает с верхнего регистра нижний.
 *
 * @param string			строка для конвертации.
 * @return		количество символов которые были переведены в нижний регистр	
 */
stock UTF8CharToLower(String:string[])
{
	new I = 0, O = strlen(string), Byte, K;
	while(I < O)
	{
		Byte = string[I];
		if(Byte >= 128)
		{
			if(Byte >= 240)
			{
				if(strlen(string[I]) < 4) break; 
				else I += 4; 
			}
			else if(Byte >= 224)
			{
				if(strlen(string[I]) < 3) break; 
				else I += 3; 
			}
			else if(Byte >= 192)
			{
				if(strlen(string[I]) < 2) break;
				Byte = (Byte % 32) * 64; 
				Byte += (string[I+1] % 64);
				if(1040 <= Byte <= 1071 || Byte == 1025 || 1030 <= Byte <= 1031 || Byte == 1168) 
				{
					if(1025 <= Byte <= 1031) Byte = Byte+80;
					else if(Byte != 1168) Byte = Byte+32;
					else Byte++;
					string[I]   = 192 + RoundToFloor(float(Byte / 64));
					string[I+1] = 128 + (Byte % 64);
					K++;
				}
				I += 2;
			}
			else break;
		}
		else
		{
			if(65 <= Byte <= 90)
			{
				string[I] = Byte+32;
				K++;
			}
			I++;
		}
	}
	return K;
}
