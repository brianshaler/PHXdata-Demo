<?
set_time_limit(10000);

$skip = 1;
$skipped = 0;
$minbuffer = 1000;
$maxbuffer = 10000;
$minquery = 2000;

$file = "data.csv";
$table = "extract";
$fields = array(  array("timestamp", "varchar"), 
                  array("double1", "double"),
                  array("double2", "double"),
                  array("int1", "int"),
                  array("char1", "varchar"));

$rows_inserted = 0;
$start_time = time();
$last_time = $start_time;
$checkup_time = 10;

$dblink = mysql_connect("database_host", "database_user", "database_password");
mysql_select_db("database_name");
$query = "";

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
  global $query, $dblink, $table, $fields, $minquery, $start_time, $last_time, $checkup_time, $rows_inserted;
  
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
  
  if ($last_time + $checkup_time <= time())
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