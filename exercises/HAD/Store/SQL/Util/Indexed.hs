module Store.SQL.Util.Indexed where

{--
In SQL database there is a concept of indexing rows of data. We capture that
concept allowing the user to distinguish between data and indices or to combine
the two, as necessary.
--}

import Database.PostgreSQL.Simple
import Database.PostgreSQL.Simple.FromRow
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.ToRow
import Database.PostgreSQL.Simple.ToField

-- the class of indexed types: you ask for the index for a, you're getting it!

class Indexed a where
   idx :: a -> Integer

data Index = Idx Integer
   deriving (Eq, Ord, Show)

instance Indexed Index where
   idx (Idx i) = i

-- Now, oftentimes, a row is inserted into the database and the index for that
-- row is autogenerated and returned as an Index value.

instance FromRow Index where
   fromRow = Idx <$> field

-- This, of course, means that there is a standard way to insert rows and get
-- their indices back. We use the Simple function 'returning' for that work.

insertRows :: ToRow a => Query -> Connection -> [a] -> IO [Index]
insertRows = flip returning

-- ... and if we have to insert the index itself as a row or column ...

instance ToRow Index where
   toRow i = [toField (idx i)]

instance ToField Index where
   toField i = toField (idx i)

{--
insertRows is called thus:

ixrows <- insertRows conn q rows

to get the indices generated for rows
--}

{-- Indexed Values ----------------------------------------------------------

Represents a row in a key-value table
--}

data IxValue a = IxV { ix :: Integer, val :: a }
   deriving (Eq, Ord, Show)

instance ToField a => ToRow (IxValue a) where
   toRow (IxV i v) = [toField i, toField v]

instance FromField a => FromRow (IxValue a) where
   fromRow = IxV <$> field <*> field

instance Indexed (IxValue a) where
   idx = ix
