<?
/**
* PHP-CLI CSV->MySQL Data Streamer
* Author: Brian Shaler :-3)
* Company: Data Realization
* Date: November 16, 2010
* 
* This script is intended to take massive CSV text files, and stream the data 
* into a MySQL database. Instead of opening the entire file, it reads chunks 
* of the file (see $maxbuffer) and inserts line by line into the database 
* using batch inserts up to $minquery characters in length. If the amount of 
* data in memory is less than $minbuffer, another chunk of data is read. This 
* goes on until the entire file has been streamed into the database. The CLI 
* script can periodically output the status, showing how long the script has 
* been executing and the number of lines inserted into the DB.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

// Skip a number of rows, usually 1 row, which is a header row.
// Run "head file.csv" to check the first few lines.
$skip = 1;
// In characters, minimum amount of data in memory
// **IMPORTANT**
// ** Make sure this number is greater than the maximum number 
// of lines in a row **
$minbuffer = 1000;
// In characters, maximum amount of data in memory
$maxbuffer = 10000;
// In characters, minimum number of characters in an INSERT query
$minquery = 2000;
// In seconds, how frequently to output status
$status_interval = 10;
// In seconds, set a maximum time for the script to run.
set_time_limit(10000);

// File to read
$file = "data.csv";
// Table to insert into
$table = "extract";

$fields = array(  array("timestamp", "varchar"), 
                  array("double1", "double"),
                  array("double2", "double"),
                  array("int1", "int"),
                  array("char1", "varchar"));

$dblink = mysql_connect("database_host", "database_user", "database_password");
mysql_select_db("database_name");

// CONFIGURATION VARIABLES ABOVE THIS LINE


// Now on to the fun part :-3)

$query = "";
$skipped = 0;
$rows_inserted = 0;
$start_time = time();
$last_time = $start_time;

function get_first_line ($str)
{
  if (strpos($str, "\n") === FALSE)
  {
    return array($str, "");
  } else
  {
    return array(substr($str, 0, strpos($str, "\n")), substr($str, strpos($str, "\n")+1));
  }
}

function padZero ($int, $len)
{
  $str = "" . $int;
  while (strlen($str) < $len) { $str = "0" . $str; }
  return $str;
}
function hms ($seconds)
{
  $remainder = $seconds;
  $hrs = $mins = $secs = 0;
  $time = "";
  if ($seconds > 3600)
  {
    $hrs = floor($remainder/3600);
    $time .= padZero($hrs, 2) . ":";
    $remainder -= $hrs*3600;
  }
  $mins = floor($remainder/60);
  $time .= padZero($mins, 2) . ":";
  $remainder -= $mins*60;
  
  $secs = $remainder;
  $time .= padZero($secs, 2);
  
  return $time;
}

function process_line ($line)
{
  global $query, $dblink, $table, $fields, $minquery, $start_time, $last_time, $status_interval, $rows_inserted;
  
  $record = explode(",", $line);
  if ($query == "")
  {
    $query = "INSERT INTO $table (";
    for ($i=0; $i < count($fields); $i++)
    {
      $query .= ($i==0 ? "" : ", ") . $fields[$i][0];
    }
    $query .= ") VALUES ";
  } else
  {
    $query .= ", ";
  }
  
  $q = array();
  for ($i=0; $i < count($fields); $i++)
  {
    switch ($fields[$i][1])
    {
      case "strtotime":
        $q[] = strtotime($record[$i]);
        break;
      case "int":
        $q[] = intval($record[$i]);
        break;
      case "double":
        $q[] = floatval($record[$i]);
        break;
      case "varchar":
        $q[] = "'{$record[$i]}'";
        break;
      default:
        die ("Invalid field type\n");
    }
  }
  $query .= "(" . implode(", ", $q) . ")";
  
  $rows_inserted++;
  
  if (strlen($query) > $minquery)
  {
    mysql_query($query) or die (mysql_error() . "\n" . $query . "\n\n");
    $query = "";
  }
  
  if ($last_time + $status_interval <= time())
  {
    echo "Run time: ".hms(time()-$start_time)."\n";
    echo "Rows: $rows_inserted\n";
    echo "===============\n";
    $last_time = time();
  }
  
}


$handle = fopen($file, "r");
$buffer = "";
$thisline = "";
while (!feof($handle))
{
  $buffer .= fread($handle, $maxbuffer-strlen($buffer));
  while (strlen($buffer) > $minbuffer)
  {
    $chunks = explode("\n", $buffer);
    $buffer = array_pop($chunks);
    
    if ($skipped < $skip)
    {
      while ($skipped < $skip && count($chunks) > 0)
      {
        array_shift($chunks);
        echo "skip: $skipped\n\n";
        $skipped++;
      }
    }
    
    foreach ($chunks as $chunk)
    {
      process_line($chunk);
    }
  }
}
while (strlen($buffer) > 0)
{
  list($chunk, $buffer) = get_first_line($buffer);
  
  process_line($chunk);
}
if (strlen($query) > 0)
{
  mysql_query($query);
  $rows_inserted++;
  $query = "";
}

fclose($handle);
mysql_close($dblink);
exit;

?>