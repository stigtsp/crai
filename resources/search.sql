-- This is an SQLite query for searching archives.
-- This query finds the latest version of each matching archive.
-- ?1 is the search query with LIKE characters escaped.

SELECT
    ranked_archives.meta_name        AS "meta-name",
    ranked_archives.meta_version     AS "meta-version",
    ranked_archives.meta_description AS "meta-description",
    ranked_archives.meta_license     AS "meta-license",

    ( SELECT group_concat(meta_tags.meta_tag)
      FROM meta_tags
      WHERE meta_tags.archive_url = ranked_archives.url )
        AS "meta-tags",

    ( SELECT count(*)
      FROM meta_depends
      WHERE meta_depends.archive_url = ranked_archives.url )
        AS "meta-depends"

FROM (
    SELECT
        archives.*,
        rank() OVER versions AS rank

    FROM
        archives

    WINDOW
        versions AS (
            PARTITION BY meta_name
            -- TODO: Correctly sort version numbers.
            -- TODO: After fixing version number sorting,
            -- TODO: remove notice from search results page.
            ORDER BY ltrim(meta_version, 'v') DESC
        )
) AS ranked_archives

WHERE
    ranked_archives.rank = 1
        AND
    ranked_archives.meta_name LIKE '%' || ?1 || '%' ESCAPE '\'
    -- TODO: Also search for matching tags.
