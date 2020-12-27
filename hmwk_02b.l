  // Dalio, Brian A.
  // dalioba
  // 2020-10-03

  //---- DEFINITIONS  --------------------------------------------

%option header-file="lex.yy.h"

/* Our input is not from an interactive source. */
%option never-interactive
/* Don't generate the default rule. */
%option nodefault
/* We don't directly read the input. */
%option noinput
/* Don't include <unistd.h>. */
%option nounistd
/* We don't 'unput' a character back. */
%option nounput
/* Don't call yywrap() on EOF. */
%option noyywrap

/* These two options are doubled to get more detailed reports. */
/* Write performance report to stderr. */
%option perf-report perf-report
/* Write statistics summary to stderr. */
%option verbose verbose

/* Generate warning messages for goofs. */
%option warn

/* Maintain current line number in yylineno. */
%option yylineno

%{
#include <errno.h>
#include <stdio.h>
#include <string.h>

// Token IDs.  Usually defined by bison.  Since this is a simple
//   flex-only solution, we define them ourselves.
//   The numbers start at 256 to avoid clashing with the literal
//   'single character' token categories.
enum {
  tok_CHAR_LIT = 256,
  tok_DBL_LIT,
  tok_ID,
  tok_INT_LIT,
  tok_STR_LIT,
};

// This union is usually defined by bison.  Since this is a
//   simple flex-only solution, we have to make it ourselves.
union {
  int intval;
  double dblval;
} yylval;

// flex doesn't track the column number automatically.  We
//   keep these up-to-date ourselves.  We want to know not
//   only the column a token begins at but also where it ends.
int yycolnoBegin;
int yycolnoEnd;

void _setTokenPos();
%}

DIGIT         [0-9]

EXPONENT      [eE][-+]?[0-9]+

%% //---- RULES --------------------------------------------------

[:,.;]   { _setTokenPos();  return yytext[0]; }

["][^\n"]*["]  {
  _setTokenPos();

  return tok_STR_LIT;
}

({DIGIT}+{EXPONENT})|({DIGIT}*({DIGIT}\.|\.{DIGIT}){DIGIT}*{EXPONENT}?)   {
  _setTokenPos();

  yylval.dblval = atof( yytext );

  return tok_DBL_LIT;
}

{DIGIT}+  {
  _setTokenPos();

  yylval.intval = atoi( yytext );

  return tok_INT_LIT;
}

[_a-zA-Z][_a-zA-Z0-9]*  {
  _setTokenPos();

  return tok_ID;
}

[ \f\t\v]+  {
  _setTokenPos();

}

[\r\n]+     { yycolnoBegin = yycolnoEnd = 0; }

.       {
  _setTokenPos();

  fprintf( stderr, "(%d:%d) Illegal character '%s' ignored.\n",
    yylineno, yycolnoBegin, yytext );
}

%% //---- USER CODE ----------------------------------------------

char *charTokens = ":,.;";

char *charTokenNames[] = {
  "COLON",
  "COMMA",
  "PERIOD",
  "SEMICOLON",
};

int main( int argc, char *argv[] )
{
  // Argument processing
  char *progName = argv[0];
  if ( argc != 2 ) {
    fprintf( stderr, "Usage: %s <inFileName>\n", progName );
    exit( 1 );
  }

  char *fileName = argv[1];
  FILE *inFP     = fopen( fileName, "r" );
  if ( inFP == NULL ) {
    fprintf( stderr, "%s: Unable to open \"%s\" for input.  (%d) %s.\n",
      progName, fileName, errno, strerror( errno ) );
    exit( 2 );
  }

  // Initialize the current location.
  //   flex updates yylineno automatically.
  //   We have to keep track of yycolnoBegin and yycolnoEnd
  //   ourselves.
  yylineno     = 1;
  yycolnoBegin = 0;
  yycolnoEnd   = 0;

  // Start reading from this input file.
  yyrestart( inFP );

  // Get the tokens one-by-one.
  int tok;
  while ( ( tok = yylex() ) ) {
    printf( "(%d:%d-%d) ", yylineno, yycolnoBegin, yycolnoEnd );

    switch ( tok ) {
      case ':' :  case ',' :  case '.' :  case ';' :
        printf( "%s\n", charTokenNames[ strchr( charTokens, tok ) - charTokens ] );
        break;

      case tok_DBL_LIT :
        printf( "DOUBLE_LITERAL %g\n", yylval.dblval );
        break;

      case tok_ID :
        printf( "ID '%s'\n", yytext );
        break;

      case tok_INT_LIT :
        printf( "INTEGER_LITERAL %d\n", yylval.intval );
        break;

      case tok_STR_LIT :
        printf( "STRING_LITERAL %s\n", yytext );
        break;

      default :
        printf( "Unknown token category %d?\n", tok );
        break;
    }
  }

  // All done!  Be tidy and get rid of allocated objects, close
  //   files, etc.
  fclose( inFP );

  // No errors!
  return 0;
}

void _setTokenPos()
{
  yycolnoBegin = yycolnoEnd + 1;
  yycolnoEnd   = yycolnoBegin + yyleng - 1;
}
//----------------------------------------------------------------
