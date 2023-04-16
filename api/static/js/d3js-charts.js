document.addEventListener("DOMContentLoaded", function () {
    const el = document.getElementById("d3js-diagram");
    const data = JSON.parse(el.getAttribute("data-json"));

    const svg = d3
        .select("#d3js-diagram")
        .append("svg")
        .attr("width", 600)
        .attr("height", 600);

    const colors = {
        blue: "rgba(75, 192, 192, 0.2)",
        green: "rgba(75, 192, 75, 0.2)",
        red: "rgba(255, 99, 132, 0.2)",
    };

    const positions = {
        red: [150, 150],
        green: [450, 150],
        blue: [300, 400],
    };

    const linesData = [
        {source: positions.red, target: positions.green, diff: data.results[0].point_diff},
        {source: positions.green, target: positions.blue, diff: data.results[1].point_diff},
        {source: positions.blue, target: positions.red, diff: data.results[2].point_diff},
    ];

    const line = d3
        .line()
        .x((d) => d[0])
        .y((d) => d[1]);

    linesData.forEach((lineData) => {
        svg
            .append("path")
            .attr("d", line([lineData.source, lineData.target]))
            .attr("stroke", "black")
            .attr("stroke-width", 2)
            .attr("fill", "none");

        const midPoint = [
            (lineData.source[0] + lineData.target[0]) / 2,
            (lineData.source[1] + lineData.target[1]) / 2,
        ];

        svg
            .append("text")
            .attr("x", midPoint[0])
            .attr("y", midPoint[1] - 5)
            .attr("text-anchor", "middle")
            .text(`VP Diff: ${lineData.diff}`);
    });

    Object.keys(colors).forEach((team) => {
        const teamData = data.results.find((result) => result.colour === team);

        svg
            .append("circle")
            .attr("cx", positions[team][0])
            .attr("cy", positions[team][1])
            .attr("r", 100)
            .attr("fill", colors[team]);

        const textLines = [
            `#${teamData.position}`,
            `Victory Points: ${teamData.victory_points}`,
            `Victory Ratio: ${teamData.vp_ratio}`,
            `Prediction: ${teamData.prediction}`,
        ];

        textLines.forEach((text, i) => {
            svg
                .append("text")
                .attr("x", positions[team][0])
                .attr("y", positions[team][1] - 30 + i * 20)
                .attr("text-anchor", "middle")
                .text(text);
        });
    });

}); // end of dom load event listener