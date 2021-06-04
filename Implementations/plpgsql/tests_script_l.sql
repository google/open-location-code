--Test script for openlocationcode functions

--###############################################################
--pluscode_cliplatitude
select pluscode_cliplatitude(149.18);
 -- pluscode_cliplatitude
-----------------
                    -- 90
-- (1 row)
select pluscode_cliplatitude(49.18);
 -- pluscode_cliplatitude
---------------------
                 -- 49.18
-- (1 row)

--###############################################################
--pluscode_normalizelongitude
select pluscode_normalizelongitude(188.18);
 -- pluscode_normalizelongitude
---------------------------
                     -- -171.82
-- (1 row)
select pluscode_normalizelongitude(288.18);
 -- pluscode_normalizelongitude
---------------------------
                      -- -71.82
-- (1 row)

--###############################################################
--pluscode_isvalid
select pluscode_isvalid('XX5JJC23+23');
 -- pluscode_isvalid
----------------
 -- t
-- (1 row)
select pluscode_isvalid('XX5JJC23+0025');
 -- pluscode_isvalid
----------------
 -- f
-- (1 row)

--###############################################################
--pluscode_codearea
select pluscode_codearea(49.1805,-0.378625,49.180625,-0.3785,10::int);
                       -- pluscode_codearea
--------------------------------------------------------------
 -- (49.1805,-0.378625,49.180625,-0.3785,10,49.1805625,-0.3785625)
-- (1 row)
select pluscode_codearea(49.1805,-1000000,49.180625,-0.3785,9::int);
                        -- pluscode_codearea
---------------------------------------------------------------
 -- (49.1805,-1000000,49.180625,-0.3785,9,49.1805625,-500000.18925)
-- (1 row)

--###############################################################
-- pluscode_isshort
select pluscode_isshort('XX5JJC+');
 -- pluscode_isshort
----------------
 -- t
-- (1 row)
select pluscode_isshort('XX5JJC+23');
 -- pluscode_isshort
----------------
 -- t
-- (1 row)

--###############################################################
-- pluscode_isfull
select pluscode_isfull('cccccc23+');
 -- pluscode_isfull
---------------
 -- t
-- (1 row)
select pluscode_isfull('cccccc23+24');
 -- pluscode_isfull
---------------
 -- t
-- (1 row)


--###############################################################
-- pluscode_encode
select pluscode_encode(49.05,-0.108,12);
 -- pluscode_encode
---------------
 -- 8CXX3V2R+2R22
-- (1 row)
select pluscode_encode(49.05,-0.108);
 -- pluscode_encode
---------------
 -- 8CXX3V2R+2R
-- (1 row)

--###############################################################
--pluscode_decode
select pluscode_decode('CCCCCCCC+');
                   -- pluscode_decode
----------------------------------------------------
 -- (78.42,-11.58,78.4225,-11.5775,8,78.42125,-11.57875)
-- (1 row)
select pluscode_decode('CC23CCCC+');
                   -- pluscode_decode
----------------------------------------------------
 -- (70.42,-18.58,70.4225,-18.5775,8,70.42125,-18.57875)
-- (1 row)
select pluscode_decode('CCCCCCCC+23');
                         -- pluscode_decode
----------------------------------------------------------------
 -- (78.42,-11.579875,78.420125,-11.57975,10,78.4200625,-11.5798125)
-- (1 row)

--###############################################################
--pluscode_shorten
select pluscode_shorten('8CXX5JJC+6H6H6H',49.18,-0.37);
 -- pluscode_shorten
----------------
 -- JC+6H6H6H
-- (1 row)
select pluscode_shorten('8CXX5JJC+',49.18,-0.37);
 -- pluscode_shorten
----------------
 -- JC+
-- (1 row)

--###############################################################
--pluscode_recovernearest
select pluscode_recovernearest('XX5JJC+', 49.1805,-0.3786);
 -- pluscode_recovernearest
-----------------------
 -- 8CXX5JJC+
-- (1 row)
select pluscode_recovernearest('XX5JJC+23', 49.1805,-0.3786);
 -- pluscode_recovernearest
-----------------------
 -- 8CXX5JJC+23
-- (1 row)
select pluscode_recovernearest('XX5JJC+2323', 49,-0.3);
 -- pluscode_recovernearest
-----------------------
 -- 8CXX5JJC+2322
-- (1 row)

