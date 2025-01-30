//
//  StringUtils.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/22/25.
//

import Foundation

func levenshteinDistance(_ a: String, _ b: String) -> Int {
    if a.isEmpty { return b.count }
    if b.isEmpty { return a.count }

    let aChars = Array(a)
    let bChars = Array(b)
    let aCount = aChars.count
    let bCount = bChars.count

    var dp = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)

    for i in 0...aCount { dp[i][0] = i }
    for j in 0...bCount { dp[0][j] = j }

    for i in 1...aCount {
        for j in 1...bCount {
            if aChars[i - 1] == bChars[j - 1] {
                dp[i][j] = dp[i - 1][j - 1]
            } else {
                dp[i][j] = min(dp[i - 1][j - 1], dp[i][j - 1], dp[i - 1][j]) + 1
            }
        }
    }

    return dp[aCount][bCount]
}
